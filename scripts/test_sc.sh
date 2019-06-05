#!/bin/bash

#create GPU Type 1
echo "=============== Creating GPU Type 1 ==============="
sleep 5
./scripts/test-network.sh invoke createGPUType GTX1080Ti 700

#create GPU Type 2
echo "=============== Creating GPU Type 2 ==============="
sleep 5
./scripts/test-network.sh invoke createGPUType RTX2080Ti 2050

#create business 1
echo "=============== Creating Business 1 (HolyTech) ==============="
sleep 5
./scripts/test-network.sh invoke createBusiness buz-1 HolyTech

#create business 2
echo "=============== Creating Business 2 (GpuLand) ==============="
sleep 5
./scripts/test-network.sh invoke createBusiness buz-2 GpuLand

#create GPU 1
echo "=============== Creating GPU 1 ==============="
sleep 5
./scripts/test-network.sh invoke createGPU gpu1 GTX1080Ti buz-2

#create GPU 2
echo "=============== Creating GPU 2 ==============="
sleep 5
./scripts/test-network.sh invoke createGPU gpu2 RTX2080Ti buz-2

#create GPU 3
echo "=============== Creating GPU 3 ==============="
sleep 5
./scripts/test-network.sh invoke createGPU gpu3 RTX2080Ti buz-2

#create an Order
echo "=============== Creating Order 1 For GPU type RTX2080Ti ==============="
sleep 5
./scripts/test-network.sh invoke createOrder order1 buz-1 buz-2 lineitem1 RTX2080Ti 2

#fill the order
echo "=============== Filling Order 1 ==============="
sleep 5
./scripts/test-network.sh invoke fillOrder order1 lineitem1 gpu3 gpu2

# transport the order
echo "=============== Shipping Order 1 ==============="
sleep 5
./scripts/test-network.sh invoke progressOrder order1 TRANSIT "false"

#deliver the order
echo "=============== Delivering Order 1 ==============="
sleep 5
./scripts/test-network.sh invoke progressOrder order1 DELIVERED "false"

#receive the order
echo "=============== Receiving Order 1 ==============="
sleep 5
./scripts/test-network.sh invoke progressOrder order1 RECEIVED "false"

#complete the order
echo "=============== Completing Order 1 ==============="
sleep 5
./scripts/test-network.sh invoke progressOrder order1 COMPLETED "false"

#delete order
echo "=============== Deleting Order 1 ==============="
sleep 5
./scripts/test-network.sh invoke deleteState order1

#Sell Gpu 1
echo "=============== Selling Gpu 3 ==============="
sleep 5
./scripts/test-network.sh invoke sellGpu gpu3 customer1 

#get history of the order
echo "=============== Getting History for Gpu ==============="
sleep 5
./scripts/test-network.sh query 0 1 getGpuHistory gpu3





