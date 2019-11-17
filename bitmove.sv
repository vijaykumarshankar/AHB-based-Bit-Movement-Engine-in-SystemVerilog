module bitmove(bitmove_intf.bm bm);
//intf 
reg mReq;
reg mRW;
reg [31:2] mAddr;
reg [31:0] mWdata;
reg [31:0] mRdata;
reg mhld;

reg errSeen;
reg done;
reg busy;
reg sRW;
reg sSel;
reg [5:3] sAddr;
reg [31:0] sWdata;
reg [31:0] sRdata;

reg [31:0] srcaddr;
reg [31:0] destaddr;
reg [4:0] srcoffset;
reg [4:0] destoffset;
reg [26:0] blklen;
reg srt;
//reg [31:0] dest_last;

reg mReq_d;
reg mRW_d;
reg [31:2] mAddr_d;
reg [31:0] mWdata_d;

reg done_d;

reg [31:0] srcaddr_d;
reg [31:0] destaddr_d;
reg [4:0] srcoffset_d;
reg [4:0] destoffset_d;
reg [26:0] blklen_d;
reg srt_d;
reg [31:0] dest_last_d, preservednew;

reg [63:0] preserved,preserved_d, preservedright;

//=======================
//local registers
reg [31:0] r0;
reg [31:0] r1;
reg [31:0] r2;
reg [31:0] r3;
reg [31:0] r4;

//=======================
//enum for state machine
typedef enum [3:0] { reset, sr1, sr2, sr3, sr4, sr5, sr6, sr7, sr8, sr9 } srstate;


srstate CS, NS;

//=======================
//flags for state machine

reg f1, f2, f3, f4, f5, f6, f7, af3;
reg f1_d, f2_d, f3_d, f4_d, f5_d, f6_d, f7_d, af3_d;

//read register 
reg [31:0] m1, m2, m3, d1, d2;

//funnel register
reg [63:0] fsreg, fsreg_d;
reg [31:0] fsregshifted, fsregshifted_d;
reg [31:0] mask, mask_d;
reg [31:0] newmask, newmask_d;
reg [31:0] spldata, spldatashiftleft, spldatashiftright,spldataright,spldataleft, middleshift ;
reg [31:0] shifted, dshifted, dshifted_d;
reg [31:0] newmaskpre, newmask_dst2, newmasked_data;

//block len
reg [26:0] blkwsrcr,blkwsrcq;
reg [26:0] blkq, rdblk;
reg [26:0] blkr;
reg [26:0] blkcount;
reg [26:0] wrblk,wrblkr,dblkcount;
reg [26:0] counter, counter_d;
reg [26:0] writebal, writebal_d;
reg [26:0] written, written_d;

//write data
reg [31:0] writedata;

//assign
assign bm.mReq = mReq_d;
assign bm.mRW = mRW_d;
assign bm.mWdata = mWdata;
assign bm.mAddr = mAddr_d;
assign bm.errSeen = errSeen;
assign bm.done = done;
assign bm.busy = busy;
assign bm.sRdata = sRdata;
assign mhld = bm.mHold;

assign blkq = blklen/32;
//assign blkr = blklen%32;
assign rdblk = ((blklen -(32 -srcoffset)) / 32  ) +1;
assign blkr = ((blklen- (32-srcoffset)) % 32)? 1 : 0;
assign blkcount = rdblk + blkr;
assign wrblk = ((blklen -(32 -destoffset)) / 32  ) +1;
assign wrblkr = ((blklen- (32-destoffset)) % 32)? 1 : 0;
assign dblkcount = wrblk + wrblkr;
//assign blkcount = blkr ? blkq + 1 : blkq;
always @(*) begin
    
    mReq_d = mReq;
    mRW_d = mRW;
    mAddr_d = mAddr;
    mWdata_d = mWdata;
    
    srcaddr_d = srcaddr;
    destaddr_d = destaddr;
    srcoffset_d = srcoffset;
    destoffset_d = destoffset;
    blklen_d = blklen;
    srt_d = srt;
    done_d = done;
 
    f1_d = f1;
    f2_d = f2;
    f3_d = f3;
    f4_d = f4;
    f5_d = f5;
    f6_d = f6;
    f7_d = f7;
    af3_d = af3;
    
    preserved_d = preserved;
    writebal_d = writebal;
    written_d = written;
    counter_d = counter;
    fsregshifted_d = fsregshifted;
    dshifted_d =  dshifted;
    mask_d = mask;
    NS = CS;
    
    if(bm.sSel && bm.sRW ) begin
        case(bm.sAddr)
            0 : r0 = bm.sWdata;
            1 : r1 = bm.sWdata;
            2 : r2 = bm.sWdata;
            3 : r3 = bm.sWdata;
            4 : r4 = bm.sWdata;
        endcase   
        srcaddr_d = {r1[31:27],r0[31:5]};
        destaddr_d = {r3[31:27],r2[31:5]};
        srcoffset_d = r0[4:0];  
        destoffset_d = r2[4:0];
        blklen_d = r1[26:0];
        srt_d = r4[0];
        writebal_d = blklen;
    end
    if(mhld == 0) begin
    case(CS)
        reset: begin
                mReq_d = 0;
                mRW_d = 0;
                mWdata_d = 0;
                done_d = 0;
                srt_d = 0;
                m1 = 0;
                m2 = 0;
                m3 = 0;
                d1 = 0;  
                d2 = 0;
                r4 = 0;
                
                fsreg = 0;
                fsregshifted_d = 0;
                mask_d = 0;
                newmask_d = 0;
                preserved_d = 0;
                preservedright = 0;
                preservednew = 0;
                
                dshifted_d = 0;
                shifted = 0;
                writedata = 0;
                writebal_d = 0;
                written_d = 0;
                
                counter_d = 0;
                
                
                newmaskpre = 0;
                newmask_dst2 = 0;
                newmasked_data = 0;
                
                spldata = 0;
                spldatashiftleft = 0;
                spldatashiftright = 0;
                spldataleft = 0;
                spldataright = 0;
                middleshift = 0;
                NS = sr1;
        end
        sr1: begin
                if(srt == 1) begin // 1st read
                    mReq_d = 1;
                    mRW_d = 0;
                    f1_d = 1;
                    f5_d = 0;
                    mAddr_d = srcaddr;
                    srcaddr_d = srcaddr+1;
                    counter_d = counter+1;
                    NS = sr2;
                   
                end
            end
            
        sr2: begin
                mReq_d = 1;            //2nd read
                mRW_d = 0;
                f2_d = 1;
                f1_d = 0;
                mAddr_d = srcaddr;
                srcaddr_d = srcaddr + 1;
                counter_d = counter + 1;
                NS=sr3;
        end
        
        sr3: begin                  //3rd read
                if(counter_d == 2) begin //3rd read 
                    mReq_d = 1;
                    mRW_d = 0;
                    f3_d = 1;
                    f2_d = 0;
                    mAddr_d = srcaddr;
                    srcaddr_d = srcaddr + 1;
                    counter_d = counter + 1;
                    NS = sr4;
                    end
                else if(counter == blkcount) begin //lastread
                    mReq_d = 1;
                    mRW_d = 0;
                    f6_d = 0;
                    f3_d = 1;
                    f2_d = 0;
                    f4_d = 0;
                    mAddr_d = srcaddr;
                    srcaddr_d = srcaddr + 1;
                    counter_d = counter + 1;
                    NS = sr8;
                end
                else begin          //after 3rd read
                    mReq_d = 1;
                    mRW_d = 0;
                    f6_d = 0;
                    f3_d = 1;
                    f4_d = 0;
                    af3_d = 1;
                    
                    mAddr_d = srcaddr;
                    srcaddr_d = srcaddr + 1;
                    counter_d = counter +1;
                    NS = sr7;
                end
        end
        
        sr4: begin                  //1st dest darta read
                    mReq_d = 1;
                    mRW_d = 0;
                    f4_d = 1;
                    f3_d = 0;
                    mAddr_d = destaddr;
                    NS = sr5;
        end
        
        sr5: begin              //last dest data read
                mReq_d = 1;
                mRW_d = 0;
                f5_d = 1;
                f4_d = 0;
                    mAddr_d = destaddr + dblkcount-1;
               
                if(blklen <32 && dblkcount ==1) begin
                    NS =sr7;
                end
                else if (blklen < 32 && dblkcount >1) begin
                    NS = sr6;
                end
                else begin
                    NS = sr6;
                    end
        end
        
        sr6: begin              //getting data ready for first
                if(counter == 3 )begin  // first write
                    mReq_d = 1;
                    mRW_d = 1;
                    f5_d = 0;
                    f6_d = 1;
                    mAddr_d = destaddr; 
                    destaddr_d = destaddr + 1;
                    fsreg = {m2[31:0],m1[31:0]};//and writing too
                    shifted = fsreg>>srcoffset;
                    mask_d = (1<<destoffset)-1;
                    writebal_d = writebal - (32 - destoffset);
                    written_d = 32-destoffset;
                    preservedright = fsreg>>srcoffset;
                    preserved_d = preservedright<<destoffset;
                    dshifted_d = shifted<<destoffset;   
                    mWdata_d = (mask_d & d1) | dshifted_d;
                    NS = sr3;   
                end
                else begin      
                end
        end
        
        sr7: begin        
                if( writebal >32 && counter >3) begin
                        mReq_d = 1; // write after 1st before last
                        mRW_d = 1;
                        f4_d = 1;
                        f3_d = 0;
                        f6_d = 1;
                        af3_d = 0;
                        mAddr_d = destaddr;
                        destaddr_d = destaddr + 1;
                        fsreg = {m2[31:0],m1[31:0]};
                        shifted =  fsreg>>srcoffset;
                        dshifted_d = shifted<<destoffset;
                        writebal_d = writebal - 32;
                        written_d = written + 32;
                        preservedright = fsreg>>srcoffset;
                        preserved_d = preservedright<<destoffset;
                        mWdata_d = preserved[63:32] | dshifted_d;
                        if(counter < blkcount) begin
                            NS = sr3;
                        end
                        else begin
                            NS = sr7;
                        end
                end
        
                else if(writebal <= 32 && blklen>32 ) begin    // last write
                    mReq_d = 1; // type here for write last 
                    mRW_d = 1;  // see how to make a mask for last
                    f4_d = 0;   // 3parts writing onto last destaddr
                    f3_d = 0;   // on more than 1 blk
                    f6_d = 0;
                    f7_d = 1;
                    af3_d = 0;
                    mAddr_d = destaddr;
                    newmaskpre = (1<<writebal)-1;
                    newmask_d = ~((1<<writebal)-1);
                    writebal_d = writebal - writebal;
                    written_d = written + writebal;
                    newmask_dst2 = newmask_d & d2;
                    newmasked_data = newmaskpre & preserved [63:32];
                    fsreg = {m2[31:0],m1[31:0]};
                    shifted =  fsreg>>srcoffset;
                    preservedright = fsreg>>srcoffset;
                    preserved_d = preservedright<<destoffset;
                    if( writebal > destoffset) begin // 3 part writing
                            spldata = preserved_d;
                            spldatashiftleft = spldata<<(32-writebal);
                            spldatashiftright = spldatashiftleft>>(32-writebal);
                            spldataright = newmask_dst2 | spldatashiftright;
                            spldataleft = (newmasked_data<<32-destoffset)>>(32-destoffset);
                            mWdata_d = spldataleft | spldataright;
                    end
                    
                    else begin //writing last 
                        mWdata_d = newmasked_data | newmask_dst2;
                    end
                    done_d = 1;
                    NS = sr9;
                end
                
                else if (blklen<32) begin
                    if (dblkcount == 1) begin
                        mReq_d = 1; // type here for write last 
                        mRW_d = 1;  // see how to make a mask for last
                        f4_d = 0;   // writing one blk and thats the last
                        f3_d = 0;
                        f6_d = 0;
                        f7_d = 1;
                        af3_d = 0;
                        mAddr_d = destaddr;
                        fsreg = {m2[31:0],m1[31:0]};
                        preservedright =  fsreg>>srcoffset;
                        dshifted_d = preservedright <<destoffset;
                        middleshift = (dshifted_d << (32-writebal-destoffset)) >> (32-writebal-destoffset);
                    
                        spldata = d1;
                        spldatashiftleft = (spldata << (32-destoffset))>>(32-destoffset);
                        spldatashiftright = (spldata >> (writebal+destoffset))<<(writebal+destoffset);
                    
                        spldataleft = spldatashiftleft | middleshift;
                        mWdata_d = spldataleft | spldatashiftright;
                    end
                    
                    else if(dblkcount>1) begin
                        mReq_d = 1; // type here for write last 
                        mRW_d = 1;  // see how to make a mask for last
                        f4_d = 0;   // writing one blk and thats the last
                        f3_d = 0;
                        f6_d = 0;
                        f7_d = 1;
                        af3_d = 0;
                        mAddr_d = destaddr;
                        newmaskpre = (1<<writebal)-1;
                        newmask_d = ~((1<<writebal)-1);
                        writebal_d = writebal - writebal;
                        written_d = written + writebal;
                        newmask_dst2 = newmask_d & d2;
                        newmasked_data = newmaskpre & preserved [63:32];
                        fsreg = {m2[31:0],m1[31:0]};
                        shifted =  fsreg>>srcoffset;
                        preservedright = fsreg>>srcoffset;
                        preserved_d = preservedright<<destoffset;
                        mWdata_d = newmasked_data | newmask_dst2;
                    end
                    else begin end
                    
                    done_d = 1;
                    NS = sr9;
                end
        
                else  begin end
        end
         
        sr8: begin              //nothing
                af3_d = 0;
                NS = sr7;
        end
        
        sr9: begin 
                    mReq_d = 0;
                    mRW_d = 0;
                    srt_d = 0;
                    f7_d = 0;
                if(bm.sSel && bm.sRW)begin
                    NS = reset;
                end
                else begin end
            end
        endcase
        end
        
        
        
end


always @(posedge(bm.clk) or posedge(bm.reset))begin
    if(bm.reset) begin
        mReq <= 0;
        mRW <= 0;
        mAddr <= 0;
        mWdata <= 0;
        mRdata <= 0;
    
        errSeen <= 0;
        done <= 0;
        busy <= 0;
        
        sRW <= 0;
		sSel <= 0;
		sAddr <= 0;
		sWdata <= 0;
		sRdata <= 0;
		
		srcaddr <= 0;
        destaddr <= 0;
        srcoffset <= 0;
        destoffset <= 0;
        blklen <= 0;
        srt <= 0;

        r0 <= 0;
		r1 <= 0;
		r2 <= 0;
		r3 <= 0;
		r4 <= 0;
		
		m1 <= 0;
		m2 <= 0;
		m3 <= 0;
		d1 <= 0;
		d2 <= 0;
		
		fsreg <= 0;
		fsregshifted <= 0;
		mask <= 0;
		newmask <= 0;
		
		f1 <= 0;
        f2 <= 0;
        f3 <= 0;
        f4 <= 0;
        f5 <= 0;
        f6 <= 0;
        f7 <= 0;
        af3 <= 0;
        
        counter <= 0;
       
        CS <= reset;
        dshifted <= 0;
        shifted <= 0;
        writedata <= 0;
        writebal <= 0;
        preserved <= 0;
        written <= 0;
    end
    
    else begin
        mReq <= #1 mReq_d;
        mRW <= #1 mRW_d;
        mAddr <= #1 mAddr_d;
        mWdata <= #1 mWdata_d;
        done <= #1 done_d;
        
        srcaddr <= #1 srcaddr_d;
        destaddr <= #1 destaddr_d;
        srcoffset <= #1 srcoffset_d;
        destoffset <= #1 destoffset_d;
        blklen <= #1 blklen_d;
        srt <= #1 srt_d;
       
        CS <= #1 NS;
		fsregshifted <= #1 fsregshifted_d;
		mask <= #1 mask_d;
		newmask <= #1 newmask_d;
		
        f1 <= #1 f1_d;
        f2 <= #1 f2_d;
        f3 <= #1 f3_d; 
        f4 <= #1 f4_d;
        f5 <= #1 f5_d;
        f6 <= #1 f6_d;
        f7 <= #1 f7_d;
        af3 <= #1 af3_d;
        
        counter <= #1 counter_d;
        
        dshifted <= #1 dshifted_d;
        writebal <= #1 writebal_d;
        written <= #1 written_d;
        preserved <= #1 preserved_d;
        
    end
    
    if (f1 == 1) begin
        m1 <= #1 bm.mRdata;
        end
    if (f2 == 1) begin
        m2 <= #1 bm.mRdata;
        end
    if (f3 == 1) begin
        m3 <= #1 bm.mRdata;
        end
    if (f4 == 1) begin
        d1 <= #1 bm.mRdata;
        end
    if (f5 == 1) begin
        d2 <= #1 bm.mRdata;
        end
    if (f6_d == 1) begin
        m1 <= #1 m2;
        m2 <= #1 m3;
        end
    if (af3 == 1) begin
        m2 <= #1 bm.mRdata;
    end
    else begin end
end
endmodule
