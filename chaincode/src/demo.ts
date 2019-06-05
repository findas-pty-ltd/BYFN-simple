import * as shim from 'fabric-shim';
import { getCiphers } from 'tls';
import { resolve } from 'url';
import { date } from 'yup';

enum OrderState {
    FAILED=-1,
    PENDING=0,
    APPROVED=1,
    TRANSIT=2,
    DELIVERED=3,
    RECEIVED=4,
    COMPLETED=5
    
}
namespace OrderState {
    let stateArray = {
        "0":"PENDING",
        "1":"APPROVED",
        "2":"TRANSIT",
        "3":"DELIVERED",
        "4":"RECEIVED",
        "5":"COMPLETED",
        "-1":"FAILED"
    };
    export function toString(mode: OrderState): string {
        return stateArray[""+mode];
    }

    export function parse(mode: string): OrderState {
        return OrderState[mode];
    }
}


interface GpuType {
    id: string;
    price: number;
}

interface Gpu {
    id: string;
    type: string;
    owner: string; //could be a line item or could be a business
}

interface Business {
    name: string;
    id: string;
}

interface Order {
    id: string;
    to:string;
    from:string;
    state: OrderState;
    owner: string;
}

interface LineItem {
    id: string;
    gpu: string; //gputype id
    owner: string; //order id
    quantity: number;
}


class hlp {
    static checkArgs(args: any[], length: number, groupsize: number = 0 , groupcount: number = 0 ) {
        // positive numbers will require in the variable needing to be equal
        // negative numbers will require the variable to be greater than or equal to 
        let mainargs = args;
        if ( groupsize !== 0 ){
            mainargs = args.slice( 0 ,  Math.abs(length)  );
        }
        let varargs = args.slice(  Math.abs(length) ,  );

        if ( length === 0 ) {
            throw new Error("ERROR: Incorrect number of args. Arg need to have a lenth > 0");
        } 
        if( length > 0 && mainargs.length !== length ) {
            throw new Error("ERROR: Incorrect number of args. Expected:"+length+" !== Recieved:"+ mainargs.length);
        }
        if( length < 0 && mainargs.length < Math.abs(length) ) {
            throw new Error("ERROR: Incorrect number of args. Expected:"+Math.abs(length)+" >== Recieved:"+mainargs.length);
        }
        if( groupsize > 0 && ! Number.isInteger( varargs.length / groupsize ) ) {
            throw new Error("ERROR: Incorrect number of args. varargs.length ("+varargs.length+") needs to be multiple of "+groupsize);
        }
        if( groupsize > 0 && groupcount > 0 && ( varargs.length / groupsize ) !== groupcount ) {
            throw new Error("ERROR: Incorrect number of args. varargs.length ("+varargs.length+") needs to have a group size of "+groupsize+" and "+groupcount+" groups");
        }
        if( groupsize > 0 && groupcount < 0 && ( varargs.length / groupsize ) <=  groupcount ) {
            throw new Error("ERROR: Incorrect number of args. varargs.length ("+varargs.length+") needs to have a group size of "+groupsize+" and more than "+groupcount+" groups");
        }
    }

    
}

export class SupplyChainCode implements shim.ChaincodeInterface {
    
    /*
        The Init function is for creating the initial state of the ledger
    */
    async Init(stub: shim.ChaincodeStub): Promise<shim.ChaincodeResponse> {
        return shim.success();
    }

    async createGPUType(stub: shim.ChaincodeStub, args: string[] ): Promise<void> {
        hlp.checkArgs(args,2);
        let gpuType: GpuType = {
            id: args[0],
            price: +args[1]
        }
        console.log("Creating GPU type settings :"+args);
        return stub.putState(gpuType.id,Buffer.from(JSON.stringify(gpuType)));
    }
    async createBusiness(stub: shim.ChaincodeStub, args: string[] ): Promise<void> {
        hlp.checkArgs(args,2);
        let buz: Business = {
            id: args[0],
            name: args[1]
        }
        return stub.putState(buz.id,Buffer.from(JSON.stringify(buz)));
    }


    async createGPU(stub: shim.ChaincodeStub, args: string[]): Promise<void> {
        console.log("creating GPU");
        hlp.checkArgs(args, 3);
        let gpu: Gpu = {
            id: args[0], 
            type: args[1], 
            owner:  args[2]
        };

        await stub.putState(gpu.id, Buffer.from(JSON.stringify(gpu)))
        .then(resp=>{
            //GPU has been created
            //creating GPU index
            this.createIndex(stub, 'tree', [gpu.owner, gpu.id])
        })
        return null;
    }

    /* The createOrder() function is for creating an order and line items to go into that order
        It accepts minimum 3 arguments inside the args[]:
            1: orderid, the id of the new order we are creating
            2: too, the id of the bussiness the order is for
            3: from, the id of the bussiness that needs to fill the order

            (optional, repeat in intervals of 3 args to create lineitem)
            4: orderlineID, this is for the id of the orderline we wish to add to order
            5: typeId, this is the type that this orderline is, e.g. 'RTX2080Ti'
            6: amount, this is for the ammount of items we wish to add to the orderline

        e.g createOrder(stub, ['order01', 'buz-1', 'buz-2', 'lineitem01', 'RTX2080Ti', '1', 'lineItem02', 'GTX1080Ti', '10'])
    */
    async createOrder(stub: shim.ChaincodeStub, args: string[] ): Promise<void>{
        //TODO check arg lengthe
        let lineitemlenth = 3;
        hlp.checkArgs(args, 3,lineitemlenth,-1);
        let order: Order = {
            id: args[0],
            to: args[1],
            from: args[2],
            state: OrderState.PENDING,
            owner: args[1]
        }
        let lineitemdata = args.slice(3,);
        let lineitemcount = lineitemdata.length/lineitemlenth;
        var lineitems: LineItem[] = [];

        for (var _i = 0; _i < lineitemcount; _i++) {
            let startindex = _i * lineitemlenth;
            lineitems.push({
                id: lineitemdata[startindex],
                gpu: lineitemdata[startindex+1],
                owner: order.id,
                quantity: +lineitemdata[startindex+2]
            });
        }
        
        await stub.putState(order.id, Buffer.from(JSON.stringify(order)))
        .then(resp=>{
            let promisses: Promise<any>[] = [];
            //Order has been writen
            // Index Order
            promisses.push(this.createIndex(stub, 'tree', [order.to, order.id]));
            
            // Write LineItems 
            for ( let lineObj of lineitems ) {
                console.log(lineObj);
                promisses.push(stub.putState(lineObj.id, Buffer.from(JSON.stringify(lineObj)))
                .then(resp=>{
                    // Index LineItem
                    return this.createIndex(stub, 'tree', [order.to, order.id, lineObj.id])
                }))
            }
            return Promise.all(promisses);
        });
        return null;
    }



    /* The progressOrder() function is for updating the state of an order

        It accepts 3 arguments inside the args[]:
            1: orderid, the id of the order we wish to progress e.g. 'order1'
            2: stateid, the state we wish to put the order in, e.g. 'APPROVED'
            3: force, this variable is for if we wish to override a order state and move it to failed or anyother state
    
    */
    async progressOrder(stub: shim.ChaincodeStub, args: string[] ): Promise<void> {
        //hlp.checkArgs(args,3);
        let orderId = args[0];
        let stateId = args[1];
        let force  = args[2] || "false";
        

        var order: Order = JSON.parse((await stub.getState(orderId)).toString('utf8'));
        var current_state = order.state;
        var to_state = OrderState.parse(stateId);
        console.log(current_state+1, to_state)
        if ( current_state+1 === to_state || force == "true" ){
            console.log("===Progressing===")
            order.state = to_state;
        } else {
            console.log("=== Error Progressing===")
            throw new Error("The progression of the order suplied is not next in order");
        }
        console.log("Order ", orderId, " is in state: ", OrderState.toString(to_state))
        return stub.putState(orderId, Buffer.from(JSON.stringify(order)))
        .then(async (res) => {
            if(order.state === OrderState.COMPLETED || order.state === OrderState.FAILED){
                var newowner: string;
                if( order.state === OrderState.COMPLETED){
                    newowner = order.to;
                }else{
                    newowner = order.from;
                }
                var queryString = {
                    selector: {
                        owner: order.id
                    }
                }
                let currentIndexs: string[][] = JSON.parse((await this.getIndex(stub,['tree' , order.to , order.id])).toString());

                console.log("current indexes: ", currentIndexs);
                let current_indexes: string[][] = currentIndexs.filter(x => { return x.length >= 4});
                console.log("current indexes: ", current_indexes);
                let status = current_indexes.map(index => {
                    
                    var newindex = index.slice(3,);
                    newindex.unshift(newowner);
                    console.log("old index: ", index, " new index: ", newindex)
                    return this.updateIndex(stub,'tree',index,newindex)
                    .then( async (res) => {
                        if (index.length===4) { 
                            console.log("updaing owner of "+index[3]+ " to be "+ newowner);
                            let rootProductKey =  index[3];
                            let object = JSON.parse((await stub.getState(rootProductKey)).toString());
                            console.log("about to put state"+ JSON.stringify(object))
                            object.owner = newowner;
                            console.log("about to put state"+ JSON.stringify(object))
                            let res = await stub.putState(object.id , Buffer.from(JSON.stringify(object)));
                        }
                    })
                })
                await Promise.all(status);
                return;
            }
        })
        
    }

    async fillOrder(stub: shim.ChaincodeStub, args: string[]): Promise<void> {
        
        var orderid = args[0];
        var lineItemId = args[1];
        var itemIDs = args.splice(2); // the remainder of items are items that will fill the line item
        var order = JSON.parse((await stub.getState(orderid)).toString('utf8'));
        var lineitem = JSON.parse((await stub.getState(lineItemId)).toString('utf8'));
        var promises: Promise<void>[] = []
        var currentID  = itemIDs[0];
        console.log(itemIDs)
        for ( let gpuId of itemIDs){
            var gpu = JSON.parse((await stub.getState(gpuId)).toString());
            console.log(gpu.id)
            if (gpu.type !== lineitem.gpu) {
                //will not add this gpu to the line item
                console.log("Type Error: gpu: "+gpuId+" : "+gpu.type+"  does not match type lineitem: "+lineitem.id+" : "+lineitem.gpu);
                break;
            }
            gpu.owner = lineitem.id;
            
            await this.updateIndex(stub,'tree',[order.from,gpu.id],[order.to,order.id,lineitem.id,gpu.id])
            .then(async(resp) => {
                await stub.putState(gpu.id, Buffer.from(JSON.stringify(gpu)))
            }).catch( err => {
                console.log(err);
            })
            
        }
       
        return this.progressOrder(stub, [orderid,OrderState.toString(OrderState.APPROVED),"true"])
        
    }

    async sellGpu(stub: shim.ChaincodeStub, args: string[] ): Promise<void> {
        hlp.checkArgs(args,2);
        console.log("Selling GPU "+ args)
        let gpuId  = args[0];
        let custId = args[1];  //----- maybe create a generic customer----- maybe create a generic customer
        const bufferObj = await stub.getState(gpuId);
        var gpuObj = JSON.parse(bufferObj.toString('utf8'));
        console.log(gpuObj)
       
        return this.updateIndex(stub,'tree',[gpuObj.owner,gpuObj.id],[custId, gpuObj.id])
        .then( () => {
            gpuObj.owner = custId; // customer id
            console.log("updating owner of gpu to ", custId)
            return stub.putState(gpuId, Buffer.from(JSON.stringify(gpuObj)))
        });
     
    }


    
    async getIndex(stub:shim.ChaincodeStub, args: string[] ): Promise<Buffer> {
        hlp.checkArgs(args, -1);
        var objectType = args[0]
        args.splice(0,1)
        const items: string[] = [];

        console.log("searching index ",objectType, args)

        return new Promise( (resolve, reject) => {
            stub.getStateByPartialCompositeKey(objectType, args).then(itorator => {
                return itorator;
            }).then( async (itorator) => {
                const items: string[][] = [];
                let done: boolean = false;   
                do{
                    const data = await itorator.next();
                    done = data.done;
                    try{
                        console.log(stub.splitCompositeKey(data.value.key).attributes)
                        items.push(stub.splitCompositeKey(data.value.key).attributes);
                    }catch(e){
                        console.log("No results found with index, ",objectType, args)
                    }
                } while (done !== true);
                return items;
          }).then((data) => {
            resolve(Buffer.from(JSON.stringify(data)));
          }).catch((err) => {
            reject(err);
          });
        });
    }

    async getState(stub:shim.ChaincodeStub,args: string[] ): Promise<Buffer> {
        hlp.checkArgs(args, 1);
        return stub.getState(args[0]);
    }

    async getStateHistory(stub: shim.ChaincodeStub, args: string[] ): Promise<Buffer> {
        hlp.checkArgs(args,1);
        let id = args[0];
        const iter = await stub.getHistoryForKey(id);
        let history : JSON[] = [];
        var done = false
        do{    
            const data = await iter.next();
            var a = new Date(data.value.timestamp.getNanos())
            done = data.done;
            try{
                let res = {
                    // "meta_data":{
                    //     "timestamp": (a.toDateString() + " " + a.toTimeString()),
                    //     "is_deleted": data.value.is_delete.toString(),
                    //     "tx_id": data.value.tx_id.toString()
                    // },
                    "data": JSON.parse(data.value.value.toString('utf8'))
                }
                history.push(JSON.parse(JSON.stringify(res)));
                
            }catch(e){
                console.log("WARN: no history "+e)
                break;
            } 
        }while(!done)
        return Buffer.from(JSON.stringify(history));
    }

    async deleteState(stub: shim.ChaincodeStub, args : string[]){
        var id = args[0]
        await stub.deleteState(id)
    }
     
    /*
        The createIndex() function is useful when searching for groups of data on the ledger.
        It accepts 3 arguments inside the args[]: 
            1: stub, is the api connecting the chaincode to the ledger
            2: indexGroup, is the name of the index we wish to search in
            3: args, is an array index values we wish to search for

        e.g: Search all products inside lineItem01 with - indexgroup ['buz-2', 'order01', 'lineItem01']
    */
    async createIndex(stub: shim.ChaincodeStub, indexGroup: string, args: string[]): Promise<void>{
        const nullValue = Buffer.from(JSON.stringify(null)); //null object for storing indexKey
        const indexKey = stub.createCompositeKey(indexGroup, args);
        return stub.putState(indexKey, nullValue);
    }

    /* 
        The updateIndex() function is for an object changes ownership we can update the index ownership tree
        This function accepts 4 arguments:

            1: stub, is the api connecting the chaincode to the ledger
            2: indexGroup, the name of index we are searching to update
            3: before[], the index value we wish to change
            4: after[], the index value we are adding too
    */
    async updateIndex(stub: shim.ChaincodeStub,indexGroup: string, before: string[], after:string[]): Promise<void> {
        console.log("updating index from ["+before+"] to ["+after+"]")
        return stub.getStateByPartialCompositeKey(indexGroup, before).then(async (itorator)  => {
            const items: string[] = [];
            let done: boolean = false;  
            let promisses: Promise<any>[] = []  
            do{
                const data = await itorator.next();
                done = data.done;
                console.log()
                let oldIndex = stub.splitCompositeKey(data.value.key).attributes
                let newIndex = oldIndex.splice(before.length);
                newIndex.unshift(...after);
                promisses.push(
                    stub.deleteState(data.value.key), 
                    this.createIndex(stub,indexGroup,newIndex)
                )       
                    
            } while (done !== true);
            return Promise.all(promisses);
        }).then((data) => {
            return Buffer.from(JSON.stringify(data));
        }).catch((err) => {
            console.log(err);
            return err;
        });
        
    }

    




    




    




    




    




    




    




    




    




    



    async Invoke(stub: shim.ChaincodeStub): Promise<shim.ChaincodeResponse> {
        let ret = stub.getFunctionAndParameters();
        console.log("=========================================================");
        console.log("Invoking With Settings:");
        console.log("Func:"+ret.fcn);
        let output:shim.ChaincodeResponse; 
        try{ 
            if(ret.fcn == 'createGPU' ){
                let payload = await this.createGPU(stub, ret.params);
                output = shim.success();
            } else if(ret.fcn == 'createGPUType' ){
                let payload = await this.createGPUType(stub, ret.params);
                output = shim.success()
            } else if(ret.fcn == 'createBusiness' ){
                let payload = await this.createBusiness(stub, ret.params);
                output = shim.success()
            } else if(ret.fcn == 'createOrder' ){
                let payload = await this.createOrder(stub, ret.params);
                output = shim.success()
            }else if(ret.fcn == "getBusiness"){
                let payload = await this.getState(stub, ret.params);
                output = shim.success(payload);
            }else if(ret.fcn == 'getOrder' ){
                let payload = await this.getState(stub, ret.params);
                output = shim.success(payload)
            }else if(ret.fcn == 'getGpuHistory'){
                let payload = await this.getStateHistory(stub, ret.params)
                output = shim.success(payload)
            }else if(ret.fcn == 'getGPUType'){
                let payload = await this.getState(stub, ret.params)
                output = shim.success(payload)
            }else if(ret.fcn == 'getGPU'){
                let payload = await this.getState(stub, ret.params)
                output = shim.success(payload)
            }else if(ret.fcn=="getOrderHistory"){
                let payload = await this.getStateHistory(stub, ret.params)
                output = shim.success(payload)
            }else if(ret.fcn == "getAll"){
                let payload = await this.getIndex(stub, ret.params)
                output = shim.success(payload)
            }else if(ret.fcn == 'progressOrder' ){
                let payload = await this.progressOrder(stub, ret.params);
                output = shim.success()
            }else if(ret.fcn == 'sellGpu' ){
                let payload = await this.sellGpu(stub, ret.params);
                output = shim.success()
            }else if(ret.fcn == 'fillOrder'){
                let payload = await this.fillOrder(stub, ret.params);
                output = shim.success()
            }else if(ret.fcn == 'deleteState'){
                let payload = await this.deleteState(stub, ret.params);
                output = shim.success()
            }else{
                throw new Error("ERROR: function "+ret.fcn+" is not avalible")
            }  
        } catch (err) {
          console.log(err);
          output = shim.error(err);
        }
        console.log("Invoke Completed with output: "+Buffer.from(JSON.parse(JSON.stringify(output.payload)).data));
        console.log("=========================================================");
        return output;
    
    }
}
