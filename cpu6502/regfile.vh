parameter REG_ZERO =4'h0;
parameter REG_A =   4'h1;
parameter REG_X =   4'h2;
parameter REG_Y =   4'h3;
parameter REG_SP =  4'h4;
parameter REG_PCL = 4'h5;
parameter REG_PCH = 4'h6;
parameter REG_T =   4'h7;
parameter REG_IL =  4'h8;
parameter REG_IH =  4'h9;

// A magic value to load PC from the I register.
parameter REG_PCI = 4'hf;
// A magic value to make the databus appear on reg output ports.
parameter REG_DB =  4'hf;
parameter REG_NUM =  16;
