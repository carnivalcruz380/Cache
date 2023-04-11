`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2023 12:43:31 AM
// Design Name: 
// Module Name: cache_top
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


module cache_top(   
  input clk,
  input reset,
  input write_policy,
  input replace_policy,
  input[1:0] inclusion_policy,
  input[47:0] cache_addr,
  input[7:0] cache_op,
  input cache_lvl,
  output reg[11:0] cache_miss_rate,
  output reg[11:0] num_reads, num_misses, num_hits,
  output reg[11:0] num_writes,
  output reg[31:0] curr_tag,
  output reg[11:0] curr_set
);

  // write_policy: 0 -> write through | 1 -> write back                         DONE
  // replace_policy: 0 -> FIFO | 1 -> LRU                                       DONE
  // inclusion_policy: 0 -> inclusive | 1 -> exclusive | 2 -> non-inclusive     IN-PROGRESS
  // cache_op: W or R
  
  parameter BLOCKSIZE = 64;

  //L1 Cache properties
  parameter L1_CACHESIZE = 8192;
  parameter L1_ASSOC = 2;
  parameter L1_NUMSETS = L1_CACHESIZE/(BLOCKSIZE * L1_ASSOC);
  reg[31:0] L1_index;         
  reg[31:0] L1_tag;
  reg[31:0] L1_cache [0:L1_NUMSETS][0:L1_ASSOC];

  //L2 Cache properties
  parameter L2_CACHESIZE = 16384;
  parameter L2_ASSOC = 4;
  parameter L2_NUMSETS = L2_CACHESIZE/(BLOCKSIZE * L2_ASSOC);
  reg[31:0] L2_index;         
  reg[31:0] L2_tag;
  reg[31:0] L2_cache [0:L2_NUMSETS][0:L2_ASSOC];

  // FSM Regs and Parameters
  parameter IDLE = 0, READ = 1, SEARCH = 2, SHIFTFULL = 3, SHIFTEMPTY = 4, LRUHIT = 5, DONE = 6;
  reg[3:0] state, next_state;
  reg[47:0] prev_addr;
  
  // Counter variables
  reg      found;
  integer i, j, lru_index;
  
  // Replacement policy FSM | Combinational logic
  always@(*)begin
   
    case(state)
        
        // Idle state for cache, keep cache state value the same
        IDLE: next_state <= (cache_addr != prev_addr) ? READ:IDLE;
        
        // Read in address to find tag, index, and block off-set
        READ: next_state <= SEARCH;
        
        // Search for tag state
        SEARCH:begin 
            
            // L1 Cache search
            if(cache_lvl)begin 
                
                // FIFO
                if(replace_policy == 0)begin
                    next_state <= (L1_cache[L1_index][L1_ASSOC-1] != 0) ? SHIFTEMPTY:SHIFTFULL;
                end

                // LRU | If cache hit, go to LRUHIT logic, if cache miss proceed with FIFO-like shifitng
                else
                    next_state <= (found) ? LRUHIT:(L1_cache[L1_index][L1_ASSOC-1] != 0) ? SHIFTEMPTY:SHIFTFULL;
            end

            // L2 Cache search
            else begin

                // FIFO
                if(replace_policy == 0)begin
                    next_state <= (L2_cache[L2_index][L2_ASSOC-1] != 0) ? SHIFTEMPTY:SHIFTFULL;
                end

                // LRU | If cache hit, go to LRUHIT logic, if cache miss proceed with FIFO-like shifitng
                else
                    next_state <= (found) ? LRUHIT:(L2_cache[L2_index][L2_ASSOC-1] != 0) ? SHIFTEMPTY:SHIFTFULL;
            end
            
        end
        
        // Shift if current cache is Full FIFO or Full LRU Miss
        SHIFTFULL: next_state <= DONE;

        // Shfit if current cache is not Full in FIFO or LRU
        SHIFTEMPTY: next_state <= DONE;
        
        // Shift logic in case of LRU hit
        LRUHIT: next_state <= DONE; 
        
        // Finish Shift operations, calculate miss rate, and jump into ideal
        DONE: next_state <= IDLE;
        
    endcase
  end
  
  // Sequential Logic for setting up FSM and initializing values
  always@(posedge clk)begin

    // Initialize values for testing
    if(reset)begin
        state <= IDLE;
        num_misses <= 8'b0;
        num_hits <= 8'b0;
        num_reads <= 8'b0;
        num_writes <= 8'b0;
        cache_miss_rate <= 12'b0;
        found <= 1'b0;
        prev_addr <= 48'b0;

        // Clear for L1
        for(i = 0; i < L1_NUMSETS; i = i + 1)begin
            for(j = 0; j < L1_ASSOC; j = j + 1)begin
                L1_cache[i][j] = 32'b0;
            end
        end

        // Clear for L2
        for(i = 0; i < L2_NUMSETS; i = i + 1)begin
            for(j = 0; j < L2_ASSOC; j = j + 1)begin
                L2_cache[i][j] = 32'b0;
            end
        end
    end
    
    // Flexible Cache Logic
    else begin
        state <= next_state;
        
        // If an address has been read, increment reads, get tag & index for FSM
        if(next_state == READ)begin
            
            // L1 Cache input
            if(cache_lvl)begin
                L1_tag <= cache_addr / BLOCKSIZE;                   // Current Tag address derived from the input cache address
                L1_index <= (cache_addr / BLOCKSIZE) % L1_NUMSETS;  // Current Set that the tag will go into
                curr_tag <= L1_tag;
                curr_set <= L1_index;
            end

            // L2 Cache input
            else begin
                L2_tag <= cache_addr / BLOCKSIZE;                   // Current Tag address derived from the input cache address
                L2_index <= (cache_addr / BLOCKSIZE) % L2_NUMSETS;  // Current Set that the tag will go into
                curr_tag <= L2_tag;
                curr_set <= L2_index;
            end
            
            // If write through & W operation increment writes
            if(write_policy == 0 && cache_op == 8'h57)begin
                num_writes = num_writes + 1;
            end
        end
        
        // Search for the tag within the current replacement policy, write policy, and inclusion policy
        else if(next_state == SEARCH)begin

                // FIFO 
                if(replace_policy == 0)begin
                
                // If tag is in L1 cache, mark as found
                if(cache_lvl)begin
                    for(i = 0; i < L1_ASSOC; i = i + 1)begin
                        if(L1_tag == L1_cache[L1_index][i])begin
                            found <= 1'b1;
                        end
                    end  
                end

                // If tag is in L2 cache, mark as found
                else begin
                    for(i = 0; i < L2_ASSOC; i = i + 1)begin
                        if(L2_tag == L2_cache[L2_index][i])begin
                            found <= 1'b1;
                        end
                    end  
                end

                // If found, increment hits, and reset found flag
                if(found)begin
                    num_hits = num_hits + 1;
                    found <= 1'b0;
                end

                // If tag is not found, increment misses and reads
                else begin
                    num_misses <= num_misses + 1;
                    num_reads = num_reads + 1;
                    
                    // If write back & W operation increment writes
                    if(write_policy == 1 && cache_op == 7'h57)begin
                        num_writes = num_writes + 1;
                    end
                end
            end
            
            // LRU
            else begin
                
                // L1 Cache | If tag found in cache, mark as found and mark LRU tag index
                if(cache_lvl)begin
                    for(i = 0; i < L1_ASSOC; i = i + 1)begin        
                        if(L1_tag == L1_cache[L1_index][i])begin
                                found <= 1'b1;
                                lru_index <= i;
                        end
                    end               
                end

                // L2 Cache | If tag found in cache, mark as found and mark LRU tag index
                else begin
                    for(i = 0; i < L2_ASSOC; i = i + 1)begin        
                        if(L2_tag == L2_cache[L2_index][i])begin
                                found <= 1'b1;
                                lru_index <= i;
                        end
                    end               
                end
            
                // If found, increment hits and clear found flag
                if(found)begin
                    num_hits = num_hits + 1;
                    found <= 1'b0;
                end

                // If not found, increment misses and reads
                else begin
                    num_misses = num_misses + 1;
                    num_reads = num_reads + 1;
                    
                    // If write back & W operation increment writes
                    if(write_policy == 1 && cache_op == 8'h57)begin
                        num_writes = num_writes + 1;
                    end
                end
            end
                       
        end
        
        // Shift logic if the cache for LRU or FIFO is full
        else if(next_state == SHIFTFULL)begin

                if(cache_lvl)begin

                    // Pop out last address out of cache before shifting
                    L1_cache[L1_index][L1_ASSOC-1] <= 32'b0;
                        
                    // Shifts through the current set with the size of the cache line to shift in FIFO order
                    for(i = L1_ASSOC; i > 0; i = i - 1)begin
                        L1_cache[L1_index][i] <= L1_cache[L1_index][i-1];
                    end
                        
                    // Insert new address at beginning of cache line
                    L1_cache[L1_index][0] <= L1_tag;
                end

                else begin

                    // Pop out last address out of cache before shifting
                    L2_cache[L2_index][L2_ASSOC-1] <= 32'b0;
                        
                    // Shifts through the current set with the size of the cache line to shift in FIFO order
                    for(i = L2_ASSOC; i > 0; i = i - 1)begin
                        L2_cache[L2_index][i] <= L2_cache[L2_index][i-1];
                    end
                        
                    // Insert new address at beginning of cache line
                    L2_cache[L2_index][0] <= L2_tag;
                end
                
        
        end
        
        // Shift logic if the cache for LRU or FIFO isn't full
        else if(next_state == SHIFTEMPTY)begin

                // L1 Cache
                if(cache_lvl)begin
                    // Shifts through the current set with the size of the cache line to shift in FIFO order
                    for(i = L1_ASSOC; i > 0; i = i - 1)begin
                        L1_cache[L1_index][i] <= L1_cache[L1_index][i-1];
                    end
                        
                    // Insert new address at beginning of cache line
                    L1_cache[L1_index][0] <= L1_tag;
                end

                // L2 Cache
                else begin
                    // Shifts through the current set with the size of the cache line to shift in FIFO order
                    for(i = L2_ASSOC; i > 0; i = i - 1)begin
                        L2_cache[L2_index][i] <= L2_cache[L2_index][i-1];
                    end
                        
                    // Insert new address at beginning of cache line
                    L2_cache[L2_index][0] <= L2_tag;
                end
        end

        // Shift logic for LRU hit
        else if(next_state == LRUHIT)begin

                // L1 cache
                if(cache_lvl)begin
                    // Pop out LRU hit tag out of cache before shifting
                    L1_cache[L1_index][lru_index] <= 32'b0;
                        
                    // Shifts through the current set with the size of the cache line to shift in LRU order
                    for(i = lru_index; i > 0; i = i - 1)begin
                        L1_cache[L1_index][i] <= L1_cache[L1_index][i-1];
                    end
                        
                    // Insert new address at beginning of cache line
                    L1_cache[L1_index][0] <= L1_tag;     
                end

                // L2 cache
                else begin

                    // Pop out LRU hit tag out of cache before shifting
                    L2_cache[L2_index][lru_index] <= 32'b0;
                        
                    // Shifts through the current set with the size of the cache line to shift in LRU order
                    for(i = lru_index; i > 0; i = i - 1)begin
                        L2_cache[L2_index][i] <= L2_cache[L2_index][i-1];
                    end
                        
                    // Insert new address at beginning of cache line
                    L2_cache[L2_index][0] <= L2_tag;     
                end
        end
        
        // Finish LRU or FIFO address insertion and calculate cache miss rate
        else if(next_state == DONE)begin
            prev_addr <= cache_addr;
            cache_miss_rate <= num_misses / (num_reads);
        end
    end
  end   

endmodule