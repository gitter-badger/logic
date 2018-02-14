/* Copyright 2018 Tymoteusz Blazejczyk
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

`include "logic.svh"

/* Module: logic_axi4_stream_transfer_counter
 *
 *
 * Parameters:
 *  COUNTER_MAX     - Maximum number of transfers.
 *  COUNTER_WIDTH   - Number of bits for internal counter.
 *  TDATA_BYTES     - Number of bytes for tdata signal.
 *
 * Ports:
 *  aclk        - Clock.
 *  areset_n    - Asynchronous active-low reset.
 *  monitor_rx  - AXI4-Stream interface.
 *  monitor_tx  - AXI4-Stream interface.
 *  tx          - AXI4-Stream interface.
 */
module logic_axi4_stream_transfer_counter #(
    int COUNTER_MAX = 256,
    int COUNTER_WIDTH = (COUNTER_MAX >= 2) ? $clog2(COUNTER_MAX) : 1,
    int TDATA_BYTES = 8 * ((COUNTER_WIDTH + 7) / 8)
) (
    input aclk,
    input areset_n,
    `LOGIC_MODPORT(logic_axi4_stream_if, monitor) monitor_rx,
    `LOGIC_MODPORT(logic_axi4_stream_if, monitor) monitor_tx,
    `LOGIC_MODPORT(logic_axi4_stream_if, tx) tx
);
    localparam int ALMOST_EMPTY = 1;
    localparam int ALMOST_FULL = COUNTER_MAX - 1;

    typedef logic [TDATA_BYTES-1:0][7:0] tdata_t;

    typedef struct packed {
        logic overflow;
        logic [COUNTER_WIDTH-1:0] value;
    } counter_t;

    logic read;
    logic write;
    counter_t counter;

    logic full;
    logic empty;
    logic almost_full;
    logic almost_empty;

    always_comb empty = almost_empty && (1'b0 == counter[0]);
    always_comb full = almost_full && (COUNTER_MAX[0] == counter[0]);

    always_comb write = monitor_rx.tvalid && monitor_rx.tready && tx.tready;
    always_comb read = monitor_tx.tvalid && monitor_tx.tready && tx.tready;

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            almost_empty <= '0;
        end
        else if (tx.tready) begin
            almost_empty <= (counter <= ALMOST_EMPTY[COUNTER_WIDTH-1:0]);
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            almost_full <= '0;
        end
        else if (tx.tready) begin
            almost_full <= (counter >= ALMOST_FULL[COUNTER_WIDTH-1:0]);
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            counter <= '0;
        end
        else if (write && !read && !full) begin
            counter <= counter + 1'b1;
        end
        else if (!write && read && !empty) begin
            counter <= counter - 1'b1;
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            tx.tvalid <= '0;
        end
        else if (tx.tready) begin
            tx.tvalid <= '1;
        end
    end

    always_comb tx.tdata = tdata_t'(counter);
    always_comb tx.tlast = '1;
    always_comb tx.tstrb = '1;
    always_comb tx.tkeep = '1;
    always_comb tx.tuser = '0;
    always_comb tx.tdest = '0;
    always_comb tx.tid = '0;
endmodule
