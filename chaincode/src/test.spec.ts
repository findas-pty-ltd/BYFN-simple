/* tslint:disable */

import { SupplyChainCode } from './demo';
import { ChaincodeMockStub, Transform } from '@theledger/fabric-mock-stub';

import { expect } from "chai";

const chaincode = new SupplyChainCode();

let stubWithInit;

class _ {
    static counter: number = 0;
    static tx():string {
        this.counter++;
        return "tx"+this.counter;
    }
}

describe('Sym Supply Chain', () => {
    const stub = new ChaincodeMockStub("MyMockStub", chaincode);


    it("Initializing network", async () => {
        let buz1 = {
            name: "HolyTech",
            id  : "buz-1"
        }
        let buz2 = {
            name: "Gpu Land",
            id  : "buz-2"
        }
        let gpuType1 = {
            id: "GTX1080Ti",
            price: 700
        }
        let gpuType2 = {
            id: "RTX2080Ti",
            price: 2250
        }

        let gpu1 = {
            id: "gpu1",
            type: "RTX2080Ti",
            owner: "buz-2"
        }
        let gpu2 = {
            id: "gpu2",
            type: "GTX1080Ti",
            owner: "buz-2"
        }
        let gpu3 = {
            id: "gpu3",
            type: "GTX1080Ti",
            owner: "buz-2"
        }

        var response;
        response = await stub.mockInit(_.tx(), []);
        expect(response.status).to.eql(200);

        console.log("Creating GPU type 1");
        response = await stub.mockInvoke(_.tx(),["createGPUType" , "GTX1080Ti" , "700"]);
        expect(response.status).to.eql(200);
        response = await stub.mockInvoke(_.tx(),["getGPUType" , "GTX1080Ti"]);
        expect(JSON.parse(response.payload.toString())).to.deep.eq(gpuType1);

        console.log("Creating GPU type 1");
        response = await stub.mockInvoke(_.tx(),["createGPUType" , "RTX2080Ti" , "2250"]);
        expect(response.status).to.eql(200);
        response = await stub.mockInvoke(_.tx(),["getGPUType" , "RTX2080Ti"]);
        expect(JSON.parse(response.payload.toString())).to.deep.eq(gpuType2);

        console.log("Creating Bussiness type 1");
        response = await stub.mockInvoke(_.tx(),["createBusiness" , "buz-1" , "HolyTech"]);
        expect(response.status).to.eql(200);
        response = await stub.mockInvoke(_.tx(),["getBusiness" , "buz-1"]);
        expect(JSON.parse(response.payload.toString())).to.deep.eq(buz1);

        console.log("Creating Bussiness type 2");
        response = await stub.mockInvoke(_.tx(),["createBusiness" , "buz-2" , "Gpu Land"]);
        expect(response.status).to.eql(200);
        response = await stub.mockInvoke(_.tx(),["getBusiness" , "buz-2"]);
        expect(JSON.parse(response.payload.toString())).to.deep.eq(buz2);

        console.log("Creating GPU 1");
        response = await stub.mockInvoke(_.tx(), ["createGPU", "gpu1", "RTX2080Ti", "buz-2"])
        expect(response.status).to.eql(200);
        response = await stub.mockInvoke(_.tx(),["getGPU" , "gpu1"]);
        expect(JSON.parse(response.payload.toString())).to.deep.eq(gpu1);

        console.log("Creating GPU 1");
        response = await stub.mockInvoke(_.tx(), ["createGPU", "gpu2", "GTX1080Ti", "buz-2"])
        expect(response.status).to.eql(200);
        response = await stub.mockInvoke(_.tx(),["getGPU" , "gpu2"]);
        expect(JSON.parse(response.payload.toString())).to.deep.eq(gpu2);

        console.log("Creating GPU 1");
        response = await stub.mockInvoke(_.tx(), ["createGPU", "gpu3", "GTX1080Ti", "buz-2"])
        expect(response.status).to.eql(200);
        response = await stub.mockInvoke(_.tx(),["getGPU" , "gpu3"]);
        expect(JSON.parse(response.payload.toString())).to.deep.eq(gpu3);
    });

    
    it("Creating Order", async () => {
        var orderobj = {
            id: "order1",
            to: "buz-1",
            from: "buz-2",
            state: 0,
            owner: "buz-1"
        }

        var response = await stub.mockInvoke(_.tx(), ["createOrder", "order1", "buz-1", "buz-2", "orderline1", "GTX1080Ti", "2"])
        expect(response.status).to.eql(200);

        var response = await stub.mockInvoke(_.tx(), ["getOrder", "order1"])
        expect(Transform.bufferToObject(response.payload)).to.deep.eq(orderobj)
    });

    it("Fill Order", async() => {
        var response = await stub.mockInvoke(_.tx(), ['fillOrder', 'order1', 'orderline1', 'gpu3', 'gpu2'])
        expect(response.status).to.eq(200);
    });

    it("Ship Order", async()=> {
        var response = await stub.mockInvoke(_.tx(), ['progressOrder', 'order1', 'TRANSIT', 'true'])
        expect(response.status).to.eq(200);
    })

    it("Deliver Order", async()=> {
        var response = await stub.mockInvoke(_.tx(), ['progressOrder', 'order1', 'DELIVERED', 'true'])
        expect(response.status).to.eq(200);
    })

    it("Receive Order", async()=> {
        var response = await stub.mockInvoke(_.tx(), ['progressOrder', 'order1', 'RECEIVED', 'true'])
        expect(response.status).to.eq(200);
    })

    it("Complete Order", async() => {
        var response = await stub.mockInvoke(_.tx(), ["progressOrder", "order1", "COMPLETED", "true"])
        expect(response.status).to.eq(200);
    });

    it("Sell GPU", async() => {
        var response = await stub.mockInvoke(_.tx(), ["sellGpu", "gpu3","cust1"])
        expect(response.status).to.eq(200);
    });
        
    it("Review Final State" , async() => {
        var response = await stub.mockInvoke(_.tx(),["getAll", "tree"])
        console.log(response.payload.toString());
        expect(response.status).to.eq(200);
    });

    it("Check GPU History", async() => {
        var response = await stub.mockInvoke(_.tx(), ["getGpuHistory", "order1"]);
        var str = JSON.stringify(JSON.parse(response.payload.toString()), null, 2);
        console.log(str)
        expect(response.status).to.eq(200);
    });

    
  
})

    