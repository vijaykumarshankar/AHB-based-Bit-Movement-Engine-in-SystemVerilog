module ahb_bridge (mAHBIF.AHBM mas, sAHBIF.AHBS sl, bitmove_intf.bridge bridge);

//master slave reg
reg mreq;
reg [31:0] mrdat;
reg [31:0] madd;
reg mrw;
reg [31:0] mwdat;

/*reg [1:0] mhtrans;
reg [2:0] mhsize;
reg [2:0] mhburst;
*/ //=====================

reg ssel,ssel_d;
reg [31:0] srdat;
reg [31:0] swdat;
reg srw, srw_d;
reg [31:0] sadd, sadd_d;

// use flipflop for ssel,srw
assign bridge.mRdata = mrdat;
assign mas.HADDR = mreq ? {madd,2'b00} : 0;
assign mas.HWDATA = mwdat;
assign mas.HWRITE = mrw;
assign mas.HBUSREQ = mreq;
/*assign mas.HBURST = 3'b000;
assign mas.HSIZE =  3'b010;
assign mas.HTRANS = mreq ? 2'b10 : 2'b00;
*/
//ahb_bridge ahb (mas.AHBM);

assign sl.HRDATA = srdat; 
/*assign bridge.sAddr = sadd; 
assign bridge.sWdata = swdat; 
assign bridge.sRW = srw; 
assign bridge.sSel = ssel; 
*/
always @(*) begin 
ssel_d = sl.HSEL;
srw_d = sl.HWRITE;
sadd_d = sl.HADDR[5:2];
swdat = sl.HWDATA;
srdat = bridge.sRdata;

bridge.sAddr = sadd; 
bridge.sWdata = swdat; 
bridge.sRW = srw; 
bridge.sSel = ssel; 
 
mreq = bridge.mReq;
mrw = bridge.mRW;
mwdat = bridge.mWdata;
madd = bridge.mAddr;
mrdat = mas.HRDATA;

bridge.mHold = sl.HREADYin ? 0 : 1;

mas.HBURST = 3'b000;
mas.HSIZE =  3'b010;
mas.HTRANS = mreq ? 2'b10 : 2'b00;
end

always @(posedge mas.HCLK or posedge mas.HRESET) begin
    if(mas.HRESET)begin
        ssel<=0; 
        srw<=0;
        sadd<=0;
    end
    else begin
        ssel <= #1 ssel_d;
        srw <= #1 srw_d;
        sadd<= #1 sadd_d;
end
end
endmodule
