`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/05/2023 03:57:04 PM
// Design Name: 
// Module Name: cache_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cache_tb();
    reg clk, reset;
    reg write_policy, replace_policy;
    reg[1:0] inclusion_policy;
    reg[47:0] cache_addr;
    reg[7:0] cache_op;
    reg cache_lvl;
    wire[11:0] num_reads, num_writes, num_misses, num_hits;
    wire[31:0] curr_tag;
    reg[11:0] curr_set;
    parameter SIZE = 100;
    
    // Test Addresses
    reg[47:0] test_addrs[0:SIZE-1] = 
    {   48'h7fff493822b8,
        48'h0000006324d8,
        48'h7fff493822b0,
        48'h7fff493822a8,
        48'h7fff493822a0,
        48'h7fff49382298,
        48'h7fff49382290,
        48'h7fff49382288,
        48'h7fff49382260,
        48'h7fff49382248,
        48'h7f3035f6f3b0,
        48'h7fff49382240,
        48'h7fff49382238,
        48'h000000634600,
        48'h7fff49382270,
        48'h0fff49382278,
        48'h7f3035f6a7c0,
        48'h0000006346e0,
        48'h7f3035f6a7c0,
        48'h000000634628,
        48'h7fff49382270,
        48'h7fff49382238,
        48'h7fff49382240,
        48'h7fff49382248,
        48'h7fff49382270,
        48'h000000634600,
        48'h7f3035f6a7c0,
        48'h000000634618,
        48'h7fff49382268,
        48'h0000006346f0,
        48'h7fff49382260,
        48'h7f3035f820c0,
        48'h7f3035f6a6b0,
        48'h7fff49382248,
        48'h7f3035f82100,
        48'h7f3035f6f160,
        48'h7fff49382240,
        48'h7fff49382238,
        48'h7fff49382230,
        48'h7fff49382228,
        48'h7f3035540400,
        48'h7f3035540488,
        48'h7f30365f1750,
        48'h7f3035541a18,
        48'h7f3035544ff4,
        48'h7f3035541a10,
        48'h7f3035541a10,
        48'h7f3035540488,
        48'h7f3035540488,
        48'h7f3035541a18,
        48'h7f3035541a14,
        48'h7f3035541a14,
        48'h7f30355404c0,
        48'h7f30355404d8,
        48'h7f303553e6b8,
        48'h7fff49382218,
        48'h7fff49382210,
        48'h7fff49382208,
        48'h7fff49382200,
        48'h7fff493821f8,
        48'h7fff493821f0,
        48'h7fff493821e8,
        48'h7f3035540400,
        48'h7f3035540430,
        48'h7f3035540428,
        48'h7fff493821d8,
        48'h00000042a5d6,
        48'h7f2fd059f000,
        48'h00000042a5d7,
        48'h7f2fd059f001,
        48'h00000042a5d9,
        48'h7f2fd059f003,
        48'h00000042a5dd,
        48'h00000042a5e5,
        48'h7f2fd059f007,
        48'h7f2fd059f00f,
        48'h7fff493821d8,
        48'h7f3035540428,
        48'h7fff493821e8,
        48'h7fff493821f0,
        48'h7fff493821f8,
        48'h7fff49382200,
        48'h7fff49382208,
        48'h7fff49382210,
        48'h7fff49382218,
        48'h7f3035540400,
        48'h7f3035540488,
        48'h7f3035541a14,
        48'h7f3035541a14,
        48'h7f3035541a18,
        48'h7f3035544ff4,
        48'h7f3035541a10,
        48'h7f3035541a10,
        48'h7fff49382228,
        48'h7fff49382230,
        48'h7fff49382238,
        48'h7fff49382240,
        48'h7fff49382248,
        48'h000000634600,
        48'h7f3035f6a7c0
    };
    
    // Test operations
    // 8'h57 = W
    // 8'h52 = R
    reg[7:0] test_ops[0:SIZE-1] =
    {   8'h57,
        8'h52,
        8'h57,
        8'h57,
        8'h52,
        8'h52,
        8'h52,
        8'h52,
        8'h57,
        8'h57,
        8'h57,
        8'h52,
        8'h52,
        8'h57,
        8'h52,
        8'h57,
        8'h52,
        8'h57,
        8'h52,
        8'h52,
        8'h57,
        8'h52,
        8'h57,
        8'h57,
        8'h52,
        8'h52,
        8'h52,
        8'h52,
        8'h57,
        8'h57,
        8'h57,
        8'h52,
        8'h52,
        8'h57,
        8'h52,
        8'h57,
        8'h52,
        8'h57,
        8'h52,
        8'h52,
        8'h57,
        8'h52,
        8'h57,
        8'h57,
        8'h52,
        8'h52,
        8'h52,
        8'h52,
        8'h57,
        8'h57,
        8'h57,
        8'h52,
        8'h52,
        8'h57,
        8'h52,
        8'h57,
        8'h52,
        8'h57,
        8'h52,
        8'h52,
        8'h57,
        8'h52,
        8'h57,
        8'h57,
        8'h52,
        8'h52,
        8'h52,
        8'h52,
        8'h57,
        8'h57,
        8'h57,
        8'h52,
        8'h52,
        8'h57,
        8'h52,
        8'h57,
        8'h52,
        8'h57,
        8'h52,
        8'h52,
        8'h57,
        8'h52,
        8'h57,
        8'h57,
        8'h52,
        8'h52,
        8'h52,
        8'h52,
        8'h57,
        8'h57,
        8'h57,
        8'h52,
        8'h52,
        8'h57,
        8'h52,
        8'h57,
        8'h52,
        8'h57,
        8'h52,
        8'h52
    };

    // TODO: Add test which level will be accessed
    //reg test_cache_lvl[0:SIZE-1]={
    //};
    
    real miss_rate;
    real misses, reads, hits, writes;
    cache_top UUT(
        .clk(clk), 
        .reset(reset), 
        .write_policy(write_policy), 
        .replace_policy(replace_policy),
        .inclusion_policy(inclusion_policy),
        .cache_addr(cache_addr),
        .num_reads(num_reads),
        .num_writes(num_writes),
        .num_misses(num_misses),
        .num_hits(num_hits),
        .curr_tag(curr_tag),
        .cache_op(cache_op),
        .curr_set(curr_set),
        .cache_lvl(cache_lvl)
        );
    integer i;
    initial begin
        replace_policy = 0;
        write_policy = 0;
        cache_lvl = 0;
        clk = 1;
        reset = 1;
        #10
        reset = 0;
                //send an addr and op from array to top module
        for(i = 0; i < SIZE; i=i+1)begin
            cache_addr = test_addrs[i];
            cache_op = test_ops[i];
            #10;

        end
        misses = num_misses;
        reads = num_reads;
        hits = num_hits;
        writes = num_writes;
        miss_rate = misses / (hits+misses);
    end
    
    always #1 clk = ~clk;

endmodule
