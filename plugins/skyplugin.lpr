library skyplugin;

{$mode objfpc}{$H+}

uses
  math,
  Classes,Sysutils
  { you can add units after this };

type
  TColor = -$7FFFFFFF-1..$7FFFFFFF;

const
  cv_StdCall = 0; //StdCall
  cv_Register = 1; //Register
   ax : array[0..7] of ShortInt = (1, 0,-1, 0, 1, 1,-1,-1);
   ay : array[0..7] of ShortInt = (0, 1, 0,-1,-1, 1, 1,-1);
   mox: array[0..2] of Integer = (50, 130, 210);
   moy: array[0..2] of Integer = (45, 125, 205);
   clBlack   = TColor($000000);
   clMaroon  = TColor($000080);
   clGreen   = TColor($008000);
   clOlive   = TColor($008080);
   clNavy    = TColor($800000);
   clPurple  = TColor($800080);
   clTeal    = TColor($808000);
   clGray    = TColor($808080);
   clSilver  = TColor($C0C0C0);
   clRed     = TColor($0000FF);
   clLime    = TColor($00FF00);
   clYellow  = TColor($00FFFF);
   clBlue    = TColor($FF0000);
   clFuchsia = TColor($FF00FF);
   clAqua    = TColor($FFFF00);
   clLtGray  = TColor($C0C0C0); // clSilver alias
   clDkGray  = TColor($808080); // clGray alias
   clWhite   = TColor($FFFFFF);


type
  TRGB32 = packed record
    B, G, R, A: Byte;
  end;
  PRGB32 = ^TRGB32;
  TRGB32Array = packed array[0..MaxInt div SizeOf(TRGB32) - 1] of TRGB32;
  PRGB32Array = ^TRGB32Array;

  TPointArray = array of TPoint;

  TFill = record
    Width, Height, Area,
    MidX, MidY, x1, y1, groups,
    x2, y2: Integer;
   end;
  TRetData = record
    Ptr : PRGB32;
    IncPtrWith : integer;
    RowLen : integer;
  end;
    TTarget_Exported = record
      Target : Pointer;

      GetTargetDimensions: procedure(target: pointer; var w, h: integer); stdcall;
      GetColor : function(target: pointer;x,y : integer) : integer; stdcall;
      ReturnData : function(target: pointer;xs, ys, width, height: Integer): TRetData; stdcall;
      FreeReturnData : procedure(target: pointer); stdcall;

      GetMousePosition: procedure(target: pointer; var x,y: integer); stdcall;
      MoveMouse: procedure(target: pointer; x,y: integer); stdcall;
      HoldMouse: procedure(target: pointer; x,y: integer; left: boolean); stdcall;
      ReleaseMouse: procedure(target: pointer; x,y: integer; left: boolean); stdcall;
      IsMouseButtonHeld : function  (target : pointer; left : boolean) : boolean;stdcall;

      SendString: procedure(target: pointer; str: PChar); stdcall;
      HoldKey: procedure(target: pointer; key: integer); stdcall;
      ReleaseKey: procedure(target: pointer; key: integer); stdcall;
      IsKeyHeld: function(target: pointer; key: integer): boolean; stdcall;
      GetKeyCode : function(target : pointer; C : char) : integer; stdcall;
    end;

var
  c, a: array of array of Integer;
  b: array of array of Boolean;
  area, bitsize, bgcolor, fillcolor,
  w, h, x1, y1, x2, y2: Integer;
  Fill: TFill;
  FillInfo: Boolean;






{
  Flood Fill algorithms
}

procedure ScanFill(x, y: Integer); register;
var
   i, xx, yy: integer;
begin
  if (c[x][y] <> bgcolor) then exit;
  c[x][y] := fillcolor;
  b[x][y] := True;
  area := area + 1;
  xx := 0;
  yy := 0;

  (* Shift Right *)
  xx := x + 1;
  while (xx < W) and (C[xx][y] = bgColor)and
  (not(B[xx][y])) do
  begin
    c[xx][y] := fillcolor;
    b[xx][y] := True;
    Area := area + 1;
    xx := xx + 1;
   end;
  if (xx - x > 1) then ScanFill(xx, y);

(* Shift Left *)
  xx := x - 1;
  while (xx > 1) and (C[xx][y] = bgColor) and
  (not(B[xx][y])) do
  begin
    c[xx][y] := fillcolor;
    b[xx][y] := True;
    Area := area + 1;
    xx := xx - 1;
   end;
  if  (x - xx > 1) then ScanFill(xx, y);

(* Shift Up *)
  yy := y + 1;
  while (yy < H) and (C[x][yy] = bgColor) and
  (not(B[x][yy])) do
  begin
    c[x][yy] := fillcolor;
    b[x][yy] := True;
    Area := area + 1;
    yy := yy + 1;
   end;
  if (yy - y > 1) then ScanFill(x, yy);

  (* Shift Down *)
  yy := y - 1;
  while (yy > 1) and (C[x][yy] = bgColor) and
  (not(B[x][yy])) do
  begin
    c[x][yy] := fillcolor;
    b[x][yy] := True;
    Area := area + 1;
    yy := yy - 1;
   end;
  if (y - yy > 1) then ScanFill(x, yy);

  for i:= 0 to bitsize do
   if (x + ax[i] > 0) and (x + ax[i] < w) and
      (y + ay[i] > 0) and (y + ay[i] < h) then
       if (not(B[x + ax[i]][y + ay[i]])) and
       (c[x + ax[i]][y + ay[i]] = bgcolor) then
    ScanFill(x + ax[i], y + ay[i]);
end;



function Max(const A, B, C: Integer): Integer; overload;
begin
  result := a;
  if b > a then
    result := b;
  if c > result then
    result := c;
end;

function Min(const A, B, C: Integer): Integer; overload;
begin
  result := a;
  if a > b then
    result := b;
  if result > c then
    result := c;
end;



procedure FFillBg(x, y: Integer); register;
var
   i: integer;
begin
  c[x][y] := fillcolor;
  area := area + 1;

  if (FillInfo) then
  begin
    Inc(Fill.Area);
    Fill.MidX := Fill.MidX + x;
    Fill.MidY := Fill.MidY + y;
    Fill.x1 := Min(Fill.x1, x);
    Fill.y1 := Min(Fill.y1, y);
    Fill.x2 := Max(Fill.x2, x);
    Fill.y2 := Max(Fill.y2, y);
  end;

  for i:= 0 to bitsize do
   if (x + ax[i] > 0) and (x + ax[i] < w) and
      (y + ay[i] > 0) and (y + ay[i] < h) then
      if (c[x + ax[i]][y + ay[i]] = bgcolor) then
    FFillBg(x + ax[i], y + ay[i]);

end;



procedure FFill(x, y: Integer); register;
var
   i: integer;
begin
  c[x][y] := fillcolor;
  b[x][y] := True;
  area := area + 1;
  for i:= 0 to bitsize do
   if (x + ax[i] > 0) and (x + ax[i] < w) and
      (y + ay[i] > 0) and (y + ay[i] < h) then
    if (not(b[x+ ax[i]][y + ay[i]])) and
    (c[x + ax[i]][y + ay[i]] = bgcolor) then
          FFill(x + ax[i], y + ay[i]);
end;


{

   Leo Solver
   By: SKy Scripter

}

var
 Data, Item: array [1..9] of record
          x1, y1, x2, y2, Parts,
          Area, Parm, mx, my, Holes,
          MinDist:Integer;
        end;








{
  Solving Coffins :)
}
procedure SolveParamerter;
var x, y, xx, yy, nic: Integer;
begin
  nic := 0;
  bgcolor := clwhite;
  fillcolor := clred;
  for y := 0 to 2 do
   for x := 0 to 2 do
   begin
    inc(nic);
    Data[nic].x1 := mox[x] + 35;
    Data[nic].y1 := moy[y] + 35;
    Data[nic].x2 := mox[x] - 35;
    Data[nic].y2 := moy[y] - 35;
    Data[nic].Parts := 0;
    Data[nic].Area := 0;
    Data[nic].MinDist := 500;
    Data[nic].mx := 0;
    Data[nic].my := 0;

    for yy := Data[nic].y2 to Data[nic].y1 do
     for xx := Data[nic].x2 to Data[nic].x1 do
      if (Sqrt(Sqr(xx - mox[x]) + Sqr(yy - moy[y])) <= 20) then
       if (c[xx][yy] = clwhite) then
       begin
          FFillBg(xx, yy);
          inc(Data[nic].Parts);
       end;

   for yy := max(moy[y] - 50, 0) to min(moy[y] + 50, h) do
     for xx := max(mox[x] - 50, 0) to min(mox[x] + 50, w) do
      if (c[xx][yy] = clred) then
      begin
         if (Data[nic].x1 > xx) then Data[nic].x1 := Max(xx - 5, 0);
         if (Data[nic].y1 > yy) then Data[nic].y1 := Max(yy - 5, 0);
         if (Data[nic].x2 < xx) then Data[nic].x2 := Min(xx + 5, w);
         if (Data[nic].y2 < yy) then Data[nic].y2 := Min(yy + 5, h);
         Data[nic].mx := Data[nic].mx + xx;
         Data[nic].my := Data[nic].my + yy;
         inc(Data[nic].Area);
         c[xx][yy] := clblue;
      end;
     Data[nic].Parm := (Data[nic].x2 - Data[nic].x1) + (Data[nic].y2 - Data[nic].y1);

        if (Data[nic].Area > 0) then
        begin
          Data[nic].mx := round(Data[nic].mx / Data[nic].Area);
          Data[nic].my := round(Data[nic].my / Data[nic].Area);
          c[Data[nic].mx][Data[nic].my] := $FF00;
       end;
   end;
end;

function CoffinAnswer: Pchar;
var i, maxparts, holes, thickitems, thinitems: integer;

begin
  maxparts := 0;
  thickitems := 0;
  thinitems := 0;
  holes := 0;
  for i := 1 to 9 do
  begin
    maxparts := max(maxparts, item[i].Parts);
    if (item[i].Area < 1700) and (item[i].Area > 530) then
    holes := holes + item[i].Holes;
    if (item[i].MinDist >= 20) then inc(thickitems) else
    if (item[i].MinDist > 5) then inc(Thinitems);
  end;

   result := 'error';
   if (maxparts > 3) then
     result := 'mining'
   else
   if (holes > 1) and (thickitems = 0) then
     result := 'farming'
   else
   if (thickitems = 0) and (thinitems = 2) then
    result := 'woodcutting'
   else
   if (thickitems = 1) and (thinitems = 3) then
    result := 'cooking'
   else
   if (thickitems > 1) then
    result := 'crafting';

end;


function RGB(R, G, B : Byte) : integer; inline;
begin
  Result := R or (G shl 8) or (B Shl 16);
end;
{   Here Goes Detecting Coffins :)      }
type
  TintArrArr = array of array of integer;
procedure FloodFill(var Area: TintArrArr; x,y,w,h : integer; findcol,replacecol : integer);
var
   stack : array of TPoint;
   StackLen : integer;
   StackIndex : integer;
   tx,ty : integer;
   ww,hh : integer;
procedure PushPt(ptx,pty : integer);
begin;
  inc(stackindex);
  stack[stackindex] := point(ptx,pty);
end;

begin;
  StackLen := w*h;
  SetLength(stack,StackLen);
  StackIndex := 0;
  Stack[0] := Point(x,y);
  ww := w - 1;
  hh := h-1;
  while StackIndex >= 0 do
  begin
    tx := Stack[StackIndex].x;
    ty := Stack[StackIndex].y;
    dec(stackindex);
    if Area[tx][ty] = findcol then
    begin
      Area[tx][ty] := replacecol;
      if tx > 0 then
        if Area[tx-1][ty] = findcol then
          Pushpt(tx-1,ty);
      if ty > 0 then
        if area[tx][ty-1] = findcol then
          pushpt(tx,ty-1);
      if tx < ww then
        if area[tx+1][ty] = findcol then
          pushpt(tx+1,ty);
      if ty < hh then
        if area[tx][ty+1] = findcol then
          pushpt(tx,ty+1);
    end;
  end;
end;

function Leo_AnalyzeCoffin(var CoffinName: PChar; ImageClient :TTarget_Exported): Boolean; Register;
var
  x, y, nic, i, dist: Integer;
  sRGB, bRGB, Hue, st: Extended;
  Line: PRGB32;
  RetData : TRetData;


label Lab1;

function RGBMin: Integer;
begin
  Result := Min(Min(Line[x].r, Line[x].g), Line[x].b);
end;

function RGBMax: Integer;
begin
  Result := Max(Max(Line[x].r, Line[x].g), Line[x].b);
end;


procedure Maskit;
begin
   sRGB := RGBMin / 255;
    bRGB := RGBMax / 255;
    Hue := 0.0;
    if (not(sRGB = bRGB)) then
    begin
       if (Line[x].r = bRGB) then
       Hue := (Line[x].g - Line[x].b) / (bRGB - sRGB)
     else if (Line[x].g = bRGB) then
       Hue := 2.0 + (Line[x].b - Line[x].r) / (bRGB - sRGB)
     else Hue := 4.0 + (Line[x].r - Line[x].g) / (bRGB - sRGB);
          Hue := Hue / 6.0;
        if (Hue < 0.0) then Hue := Hue + 1;
     end;
    if (Hue < 13.0) then
        c[x][y] := 0
    else
        c[x][y] := clwhite;
end;

begin
  Result := False;
  CoffinName := 'error';
  w := 240; h := 237;
   for nic := 1 to 9 do
     Item[nic].Parm := 0;
  SetLength(c, w + 1, h + 1);
  SetLength(b, w + 1, h + 1);
  bitsize := 7;
  st := now;

 repeat
    RetData := ImageClient.ReturnData(ImageClient.Target,145,50,w,h);
 {    Filter Pixels (Get Mask)      }
 Area := 0;
  for y := 0 to h-1 do
  begin
    Line := RetData.Ptr + RetData.RowLen*y;
   for x := 0 to w-1 do
   begin
     c[x][y] := RGB(Line[x].R, Line[x].G, Line[x].B);
     b[x][y] := false;
     Maskit;
   end;
 end;

 SolveParamerter;
{  for y := 0 to h do
  for x := 0 to w do
   Bmp.Canvas.Pixels[x, y] := c[x][y];
   Bmp.Canvas.Brush.Color := 10;
     Bmp.Canvas.FloodFill(2, 2, 0, fsSurface);
   Bmp.Canvas.FloodFill(w - 2, h - 2, 0, fsSurface);}
  FloodFill(c,2,2,w,h,0,10);
  FloodFill(c,w-2,h-2,w,h,0,10);

{ for y := 0 to h do
  for x := 0 to w do
   c[x][y] := bmp.Canvas.Pixels[x, y];}

 for nic := 1 to 9 do
 begin
   if (Data[nic].Parm > Item[nic].Parm) then
   begin
     Item[nic] := Data[nic];
     Item[nic].Holes := 0;

          // Corners
      for y := Item[nic].y1 to Item[nic].y2 do
       for x := Item[nic].x1 to Item[nic].x2 do
        if (c[x][y] = clblue) then
        begin
        for i := 0 to 7 do
        if (X + ax[i] > 0) and (X + ax[i] < w) and
           (Y + ay[i] > 0) and (Y + ay[i] < h) then
             if (c[x + ax[i]][y + ay[i]] = 10) then
             begin
                 c[x][y] := $CCFF;
                 break;
             end;
       end;
      Item[nic].MinDist := 500;
      fillcolor := clpurple;
      bgcolor := 0;
       for y := Item[nic].y1 to Item[nic].y2 do
        for x := Item[nic].x1 to Item[nic].x2 do
        begin
         if (c[x][y] = 0) then
         begin
           Area := 0;
           FFillBg(x, y);
           if (Area > 5) then inc(Item[nic].Holes);
         end;
         if (c[x][y] = $CCFF) then
         begin
            Dist := round(Sqrt(Sqr(1.0 * (x - Item[nic].mx)) + Sqr(1.0 * (y - Item[nic].my))));
            if (Item[nic].MinDist > Dist) then Item[nic].MinDist := Dist;
         end;
     end;
   end;
 end;
 Sleep(150 + random(50));
 ImageClient.FreeReturnData(ImageClient.Target);

until (((Now - st) * 86400000) > 10000);
  CoffinName := CoffinAnswer;

Lab1:


end;


{   Here Goes Detecting GraveStones :)      }


function Leo_AnalyzeGraveStone( var StoneName: PChar; ImageClient :TTarget_Exported): Boolean; Register;
var
  x, y, MaxArea, Pixels, i,
  fx, fy, Holes, MinDist,
  mx, my, Dist, HistoArea: Integer;
  HG: array [0..1000] of Integer;
  Done: Boolean;
  st, lum: Extended;
  Line: PRGB32;
  RetData : TRetData;
label Lab1;
begin
  Result := False;
  StoneName := 'error';
  w := 350; h := 270;
  SetLength(c, w + 1, h + 1);
  SetLength(b, w + 1, h + 1);
  bitsize := 7;
  st := Now;
  Done := false;
  fx := 0; fy := 0;
  dec(w); dec(h);
repeat
  { Copy Canvas From Screen }
  RetData := ImageClient.ReturnData(ImageClient.Target,100,50,w+1,h+1);
//  BitBlt(Bmp2.Canvas.Handle, 0, 0, w, h, ClientHDC, 100, 50, SRCCOPY);
  fillchar(HG, sizeof(HG), 0);

 {    Get Pixels      }

  for y := 0 to h do
  begin
     Line := RetData.Ptr + RetData.RowLen * y;

   for x := 0 to w do
   begin
     c[x][y] := RGB(Line[x].R, Line[x].G, Line[x].B);
     b[x][y] := false;
     Lum := (Line[x].R + Line[x].G + Line[x].B) / 765;
    if (lum < 0.3) then c[x][y] := 0;

  with Line[x] do
    inc(HG[round(Sqrt(R*R + G*G + B*B))]);

   end;
 end;



 { Delete Large Mass of Pixels (The Background) }
 try
 for y := 0 to h do
   for x := 0 to w do
    if (not(b[x][y])) and (c[x][y] <> 0) then
   begin
     bgcolor := c[x][y];
     fillcolor := c[x][y];
     Area := 0;
     ScanFill(x, y);
    if (Area > 180) then
    begin
      fillcolor := 0;
      FFillBg(x, y);
    end;
   end;
  except end;

 x1 := w;
 y1 := h;
 x2 := 0;
 y2 := 0;
  { Measure The Box Coords }
 for y := 5 to h-5 do
  for x := 5 to w-5 do
   if (c[x][y] <> 0) then
   begin
       if (x < x1) then x1 := x - 15;
       if (y < y1) then y1 := y;
       if (x > x2) then x2 := x + 15;
       if (y > y2) then y2 := y;
   end;
 if ((x2 - x1) >= 180) and ((y2 - y1) >= 180) then Done := True;
 Sleep(100);
 ImageClient.FreeReturnData(ImageClient.Target);
until (((Now - st) * 86400000) > 15000) or (Done);
 if (not(done)) then goto lab1;


 // Paint All Object Pixels White
 for y := y1 to y2 do
  for x := x1 to x2 do
   if (c[x][y] > 0) then
   begin
     b[x][y] := false;
     c[x][y] := clwhite;
   end;

  bgcolor := clwhite;
  fillcolor := clblue;
  MaxArea := 0;
  fx := 0;
  fy := 0;

 for y := y1 to y2 do
  for x := x1 to x2 do
   if (c[x][y] = clwhite) then
   begin
      Area := 0;
      FFillBg(x, y);
     if (MaxArea < Area) then
     begin                 // Find Biggest Object and paint it red
       MaxArea := Area;
       fx := x;
       fy := y;
     end;
   end;


  Area := 0;
  bgcolor := clblue;
  fillcolor := clred;
  FFillBg(fx, fy);
  Pixels := Area;
  if (Pixels < 3000) then goto lab1;

{ bmp2.canvas.brush.color := 0;
 bmp2.Canvas.Brush.Style := bsSolid;
 bmp2.Canvas.Rectangle(0, 0, w, h);

 Blank BMP (or just blank C)
 }

 for y := 0 to h do
  for x := 0 to w do
  begin
    if not (c[x][y] = 255) then
      c[x][y] := 0;
// Only set 255 pixels to true
//    if (C[x][y] = clblue) then c[x][y] := 0;
//    if (c[x][y] = 255) then bmp2.Canvas.Pixels[x, y] := c[x][y];
  end;
  FloodFill(c,3, 3,w+1,h+1, 0, 10);
  FloodFill(c,w - 3, h - 3,w+1,h+1, 0, 10);
{
  Floodfill and translate back
   bmp2.Canvas.Brush.Color := 10;
   bmp2.Canvas.FloodFill(3, 3, 0, fsSurface);
   bmp2.Canvas.FloodFill(w - 3, h - 3, 0, fsSurface);

 for y := 0 to h do
   for x := 0 to w do
    c[x][y] := bmp2.Canvas.Pixels[x, y];    }

    { Farm / Cook Detect }

 Holes := 0;
 BgColor := 0;
 FillColor := clpurple;
  // Count Holes
 for y := y1 to y2 do
  for x := x1 to x2 do
   if (c[x][y] = 0) then
   begin
        Area := 0;
        FFillBg(x, y);
     if (Area > 100) then
         Holes := Holes + 1;
   end;

  x := 0;
  HistoArea := 0;

   for i:= 1000 downto 0 do
    if (HG[i] > 0) then
    begin
       HistoArea := HistoArea + HG[i];
       inc(x);
       if x > 20 then
        break;
    end;

   HistoArea := round(HistoArea / 10);

  if (Pixels > 10000) and (HistoArea > 1000) then
   StoneName := 'cooking'
else
  if (Holes > 0) and (Pixels < 10000) then
    StoneName := 'farming';


 if (not(StoneName = 'error')) then
 begin
   Result := True;
   goto Lab1;
 end;

 if (Holes > 0) then goto Lab1;

// Here Is WoodCutting, Mining and Crafting
 { Bold Object to make it fit better }
 for y := y1 to y2 do
  for x := x1 to x2 do
   if (c[x][y] = clred) and (not(b[x][y])) then
    for i := 0 to 7 do
     begin
        c[x + ax[i]][y + ay[i]] := clred;
        b[x + ax[i]][y + ay[i]] := true;
     end;

  mx := 0;
  my := 0;
  area := 0;

  { Detect Edges And Get the center point of the object }
  for y := y1 to y2 do
  for x := x1 to x2 do
   if (c[x][y] = clred) then
   begin
    for i := 0 to 7 do
     if (c[x + ax[i]][y + ay[i]] = 10) then
      c[x + ax[i]][y + ay[i]] := clwhite;

     mx := mx + x;
     my := my + y;
     area := area + 1;
    end;

 mx := round(mx / area);
 my := round(my / area);

 c[mx][my] := clgreen;
  for i := 0 to 7 do
   c[mx + ax[i]][my + ay[i]] := clgreen;

  MinDist := 500;
  for y := y1 to y2 do
   for x := x1 to x2 do
    if (c[x][y] = clwhite) then
    begin
       Dist := Round(Sqrt(Sqr(x - mx) + Sqr(y - my)));
       if (MinDist > Dist) then
       begin
           MinDist := Dist;
           fx := x;
           fy := y;
       end;
    end;

   c[fx][fy] := clpurple;
   for i := 0 to 7 do
    if (c[fx + ax[i]][fy + ay[i]] <> 0) then
     c[fx + ax[i]][fy + ay[i]] := clpurple;

   if (MinDist >= 20) then
   begin
      StoneName := 'crafting';
     result := true;
     goto lab1;
  end;


    x := 0;
  HistoArea := 0;

   for i:= 1000 downto 0 do
    if (HG[i] > 0) then
    begin
       HistoArea := HistoArea + HG[i];
       inc(x);
       if x > 15 then
        break;
    end;


  if (MinDist > 0) then
  begin

   if ((HistoArea > 3300) and (MinDist > 4)) or (HistoArea > 3900) then StoneName := 'mining'
 else
    if ((HistoArea < 2700) and (MinDist < 6)) or (HistoArea < 2000) then StoneName := 'woodcutting'
 end;



   if (not(StoneName = 'error')) then Result := True;
Lab1:

{  for y := 0 to h do
   for x := 0 to w do
   canvas.pixels[x, y] := c[x][y];
}

end;




{

  Quiz Solver
  by: SKy Scripter
}
var
  q_Items: array [0..2] of record
     name: string;
     mx, my, param, holes,
     mindist, maxdist, count, parea: Integer;
   end;

function q_ItemBounds(I: Integer): Integer;
var
  xs, ys, xe, ye, x, y: Integer;
begin
  x1 := w;    x2 := 0;
  y1 := h;    y2 := 0;
  xs := (I * 160) + 4; ys := 4;
  xe := (xs + 160) - 4;  ye := 114;
  result := 0;

  for y := ys to ye do
   for x := xs to xe do
   begin
     if (y = ys) or (y = ye) or
        (x = xs) or (x = xe) then
        c[x][y] := clblue;
   if (c[x][y] = clred) then
   begin
       if (x2 < x) then x2 := x;
       if (y2 < y) then y2 := y;
       if (x1 > x) then x1 := x;
       if (y1 > y) then y1 := y;

   end;
  end;

   if (x2 > x1) then
   Result:= (x2 - x1) + (y2 - y1);

end;

procedure q_InitializeItem(I: Integer);
var
  xs, ys, xe, ye,
  x, y, n, dist, parea: Integer;
begin
  xs := (I * 160) + 4; ys := 4;
  xe := (xs + 160) - 4;  ye := 114;
  q_Items[I].name := '';
  q_Items[I].holes := 0;
  q_Items[I].mindist := 500;
  q_Items[I].maxdist := 0;
  bgcolor := 0;
  fillcolor := clpurple;
  q_Items[I].parea := 0;
  q_Items[I].mx := 0;
  q_Items[I].my := 0;
  q_Items[I].count := 0;

  for y := ys to ye do
   for x := xs to xe do
   if (c[x][y] = clred) then
   begin
     Inc(q_Items[I].count);
     q_Items[I].mx := q_Items[I].mx + x;
     q_Items[I].my := q_Items[I].my + y;
   end;
  if  (q_Items[I].count < 5) then exit;
 q_Items[I].mx := round(q_Items[I].mx / q_Items[I].Count);
 q_Items[I].my := round(q_Items[I].my / q_Items[I].Count);

 if (c[q_Items[I].mx][q_Items[I].my] < 11) then
  inc(q_Items[i].holes);

  for y := ys to ye do
   for x := xs to xe do
   begin
    if (c[x][y] = clred) then
    begin
     for n := 0 to 3 do
      if (c[x + ax[n]][y + ay[n]] = 10) then
      begin
        c[x][y] := clblue;
         dist := round(Sqrt(Sqr(x - q_Items[I].mx) + Sqr(y - q_Items[I].my)));
      if (q_Items[I].maxdist < Dist) then
        q_Items[I].maxdist := Dist;
      if (q_Items[I].mindist > Dist) then
        q_Items[I].mindist := Dist;
        inc(q_Items[I].parea);
        break;
      end;
    end;
    if (c[x][y] = 0) then
    begin
      Area := 0;
      FFillBg(x, y);
      if (Area > 10) then
       Inc(q_Items[I].holes);
    end;
   end;

    C[q_Items[I].mx][q_Items[I].my] := $CCFF;
    for n := 0 to 3 do
     C[q_Items[I].mx + ax[n]][q_Items[I].my + ay[n]] := $CCFF;
end;


function Quiz_AnalyzeQuiz( ImageClient: TTarget_Exported; var objx, objy: Integer; var nameresult: PChar): Boolean;   Register;
var
  Line: PRGB32;
  x, y, I, n, fishcount, b, cnt: Integer;
  st: Extended;
  sR, bR: integer;
  Parms: array [0..2] of Integer;
  Retdata : TRetData;


function InR(ssR, bsR, sbR, bbR: Integer): boolean;
begin
  result := (sR <= bsR) and (sR >= ssR) and
            (bR >= sbR) and (bR <= bbR);
end;

label leave;
 // every 164 pixels
begin
  w := 492; h := 118;
  try
  SetLength(c, w + 1, h + 1);
  bitsize := 7;
  b := 0;
  Result := false;
  b := b + 1;
   if (b > 2) then goto leave;
  st := now;
  for i := 0 to 2 do
   q_items[i].param := 0;
repeat
  Retdata := ImageClient.ReturnData(ImageClient.Target,19,357,w,h);
//  BitBlt(Bmp.Canvas.Handle, 0, 0, w, h, ClientHDC, 19, 357, SRCCOPY);
  cnt := 0;
  for y := 0 to h-1 do begin
    Line := RetData.Ptr + Retdata.RowLen * y;//bmp.ScanLine[y];
   for x := 0 to w-1 do  begin
     c[x][y] := 0;
     if (Line[x].B > 0) and (Line[x].B < 99) then
     c[x][y] := clred;
     if (Line[x].b = 0) then inc(cnt);
    Line[x].B := 0; Line[x].R := 0; Line[x].G := 0;
     if (c[x][y] = clred) then
        Line[x].R := 255;
   end;
 end;

 if (Abs(cnt - 431) >= 30) then goto Leave;
    cnt := 0;

  for i := 0 to 2 do begin
    Parms[I] := q_ItemBounds(I);
   if (Parms[I] > q_Items[I].param) then inc(cnt);
 end;

 if (cnt > 0) then begin
   FloodFill(c,2,2,w,h,0,10);
   FloodFill(c,w-2,h-2,w,h,0,10);
{   Bmp.Canvas.Brush.Color := 10;
   Bmp.Canvas.FloodFill(2, 2, 0, fsSurface);
   Bmp.Canvas.FloodFill(w-2, h-2, 0, fsSurface);

 for y := 0 to h-1 do begin
    Line := bmp.ScanLine[y];
   for x := 0 to w-1 do  begin
     c[x][y] := rgb(Line[x].r, Line[x].g, Line[x].b);
   end;
 end; }
end;

  bgcolor := clwhite;
  fillcolor := clblue;

  for i := 0 to 2 do
   if (Parms[I] > q_Items[I].param) then
   begin
     q_Items[I].param := parms[i];
     q_InitializeItem(I);
   end;

 Sleep(100);
 ImageClient.FreeReturnData(ImageClient.Target);
until (((Now - st) * 86400000) > 10000);
fishcount := 0;

for i := 0 to 2 do begin
q_items[i].name := 'non fish';
sR := round(q_Items[i].mindist / q_Items[i].parea * 100);
bR := round(q_Items[i].maxdist / q_Items[i].parea * 100);

if (q_Items[i].holes < 1) and (q_Items[i].param > 100) and (q_Items[i].param < 111) then
if InR(4, 8, 20, 28) or  InR(4, 8, 14, 21) then begin
  q_items[i].name := 'fish';
  inc(fishcount);
 end;
end;
  i := -1;

case fishcount of
 0: begin   // there are other groups but tools seem to be most common.
       Writeln('Found no fish. Finding non tool.. ');

       for i := 0 to 2 do begin
       q_items[i].name := 'non tool';
        if (q_items[i].count < 320) or ((q_items[i].count > 1000) and (q_items[i].count < 1350) and
        (q_items[i].param >= 114) and (q_items[i].param <= 120)) then
         q_items[i].name := 'tool';
       end;

     for i := 0 to 2 do
     if (q_items[i].name = 'non tool') then begin
      nameresult := 'non tool';
      break;
     end;
       if (nameresult = '') then
         i := random(3);
  end;

 3:   i := random(3);
 1:  nameresult := 'fish';
 2:  nameresult := 'non fish';
end;

result := (i > -1);

 if (result) and (nameresult = '') then begin
  nameresult := 'guess';
  writeln('Found something wrong. Guessing....');
 end;

 if (i = -1) then
  for i := 0 to 2 do
   if (q_items[i].name = nameresult) then  begin
     result := true;
      break;
  end;

if (Result) then
begin
  objx := q_items[i].mx + random(10);
  objy := q_items[i].my + 357 + random(10) - 5;
  Writeln('found a '+nameresult +' In slot #'+inttostr(i+1) + ' at ('+inttostr(objx)+','+inttostr(objy)+')');
end;

leave:
{ for y := 0 to h do
  for x := 0 to w do
   canvas.Pixels[x, y] := c[x][y];
   DEBUGFUCKYOU}
finally


end;

end;


{
   Certer Solver
   by: Sky Scripter

}

{procedure Certer_CountCerterPixels(Canvas: TCanvas; width, height: Integer; var wi, hi: integer); register;
var
   x, y, c: Integer;
begin
  BgColor := Canvas.Pixels[5, 5];
  hi := 0;
  wi := 0;
  x1 := width;
  y1 := height;
  x2 := 0;
  y2 := 0;
  for y := 0 to height do
   for x := 0 to width do
   begin
     c := Canvas.Pixels[x, y];
     if (c <> BgColor) and (c > 0) then
     begin
       if (x1 > x) then x1 := x;
       if (y1 > y) then y1 := y;
       if (x2 < x) then x2 := x;
       if (y2 < y) then y2 := y;
     end;
   end;
   wi := (x2 - x1);
   hi := (y2 - y1);
end; }



{function Certer_DistinguishPicture(Canvas: TCanvas; var Item: string; width, height: Integer; Debug: Boolean): Boolean; register;
var
  x, y, MaxArea, mx, my,
  i, MinDist, MaxDist, Dist: Integer;

function MinDR(mi, ma: integer): Boolean;
begin
  Result := (MinDist >= Mi) and (MinDist <= Ma);
end;

function MaxDR(mi, ma: integer): Boolean;
begin
  Result := (MaxDist >= Mi) and (MaxDist <= Ma);
end;

label label1;
begin
  w := width - 1;
  h := height - 1;
  bitsize := 7;
  Result := False;
  SetLength(c, w + 1, h + 1);
  SetLength(b, w + 1, h + 1);

  BgColor := Canvas.Pixels[2, 2];
  Canvas.Brush.Color := 0;
  Canvas.FloodFill(2, 2, BgColor, fsSurface);

  { Load Pixels }
  Area := 0;
  mx := 0;
  my := 0;
  x1 := w;
  y1 := h;
  x2 := 0;
  y2 := 0;

  for y := 0 to h do
   for x := 0 to w do
   begin
     C[x][y] := Canvas.Pixels[x, y];
     if (C[x][y] <> BgColor) and (C[x][y] > 0) then
     begin
       C[x][y] := Clwhite;
       Area := Area + 1;
       mx := mx + x;
       my := my + y;

       if (x1 > x) then x1 := x - 2;
       if (y1 > y) then y1 := y - 2;
       if (x2 < x) then x2 := x + 2;
       if (y2 < y) then y2 := y + 2;
     end;
     B[x][y] := False;
   end;

   if (Area < 10) then Exit;
    mx := round(mx / area);
    my := round(my / area);



   {
     Find Holes
     Shovel, Shears and Ring.
   }
  MaxArea := 0;
  fillcolor := clpurple;
  for y := y1 to y2 do
   for x := x1 to x2 do
   begin
    if (x = x1) or (x = x2) or
       (y = y1) or (y = y2) then
       c[x][y] := clSkyBlue;

    if (c[x][y] = bgColor) then
    begin
        Area := 0;
        FFillBg(x, y);
     if (Area > MaxArea) then
     MaxArea := Area;
    end;

    if (c[x][y] = clwhite) then
     for i := 0 to 3 do
      if (c[x + ax[i]][y + ay[i]] = 0) then
      c[x][y] := clred;

  end;

   if (MaxArea > 10) then
   begin
     if (MaxArea > 150) then
       Item := 'ring'
    else
       if ((x2 - x1) + (y2 - y1) > 100) then
       Item := 'spade'
    else
       Item := 'pair';
   end;


   if (Item <> '') then
   begin
     Result := True;
     goto Label1;
   end else
  if (c[mx][my] = 0) then
   begin
    Result := True;
     Item := 'pair';
     goto Label1;
    end;

   MinDist := 500;
   MaxDist := 0;

  for y := y1 to y2 do
   for x := x1 to x2 do
     if (c[x][y] = clred) then
     begin
       Dist := Round(Sqrt(Sqr(x - mx) + Sqr(y - my)));
       if (MinDist > Dist) then MinDist := Dist;
       if (MaxDist < Dist) then MaxDist := Dist;
     end;

     { Special Thanks to Pups.. This is his data
      and it happen to save me a lot of time. }

 if MaxDR(30, 40) and MinDR(-1, 3) then
    Item := 'pair';
  if MaxDR(65, 100) and MinDR(5, 20) then
    Item := 'fish';
  if MaxDR(50, 65) and MinDR(1, 8) then
    Item := 'axe';
  if MaxDR(42, 54) and MinDR(0, 4) then
    Item := 'sword';
  if MaxDR(21, 29) and MinDR(7, 20) then
    Item := 'helmet';
  if MaxDR(40, 50) and MinDR(20, 30) then
    Item := 'shield';
  if MaxDR(28, 40) and MinDR(28, 40) then
    Item := 'bowl';


   if (Item <> '') then
    begin
      Result := True;
      goto label1;
    end;

label1:
 if (Debug) then
 begin
   c[mx][my] := clblue;
     for i := 0 to 7 do
      c[mx + ax[i]][my + ay[i]] := clblue;

  for y := 0 to h do
   for x := 0 to w do
    Canvas.Pixels[x, y] := C[x][y];
 end;
end;       }

                                      {
function FindTail234(TailSize: Integer): Boolean;
var
   x, y, fx, fy, i, count: Integer;
   mx, my, dx, dy, ad, dist, cornercount, maxdist: Integer;
   tailfound, bc, greenarea: Integer;

procedure Clear;
begin
      fill.Area := 0;
      Fill.MidX := 0; Fill.MidY := 0;
      Fill.x1 := w; Fill.y1 := H;
      Fill.x2 := 0; Fill.y2 := 0;
end;

label db, db2;
begin

 Result := false;

  for y := 0 to H do
   for x := 0 to W do
    if (c[x][y] = clred) then
    begin
      area := 0;
      Clear;
      FillInfo := True;
      bgcolor := clred;
      fillcolor := clwhite;
      bitsize := 7;
      FFillBg(x, y);
      if (Fill.x1 = w) and (Fill.y1 = h) then continue;

      Fill.x1 := Max(Fill.x1 - 5, 2);   Fill.y1 := Max(Fill.y1 - 5, 2);
      Fill.x2 := Min(Fill.x2 + 5, w-2); Fill.y2 := Min(Fill.y2 + 5, h-2);

      if Area > 20 then
      begin

      count := 0;
      area := 0;
      dx := 0;
      dy := 0;
          for fy := Fill.y1 to Fill.y2 do
           for fx := Fill.x1 to Fill.x2 do
           begin
             if (c[fx][fy] = clblue) then
             begin
                c[fx][fy] := 0;
                dx := dx + fx;
                dy := dy + fy;
                inc(area);
             end;

             if (c[fx][fy] = clred) then
             begin
               count := count + 1;
               goto db;
             end;
          end;

      db:
        if (Count > 0) or (area < 1) then
      Break;

      dx := round(dx / area);
      dy := round(dy / area);

     for fy := Fill.y1 to Fill.y2 do
       for fx := Fill.x1 to Fill.x2 do
         if (c[fx][fy] = clwhite) then
          begin
             Clear;
              area := 0;
              FillInfo := True;
              bgcolor := clwhite;
              fillcolor := clLime;
              FFillBg(fx, fy);
             goto db2;
          end;

    db2:
     Fill.x1 := Max(Fill.x1 - 5, 2);   Fill.y1 := Max(Fill.y1 - 5, 2);
     Fill.x2 := Min(Fill.x2 + 5, w-2); Fill.y2 := Min(Fill.y2 + 5, h-2);


    for fy := Fill.y1 to Fill.y2 do
      for fx := Fill.x1 to Fill.x2 do
        if (c[fx][fy] > 0) then
         if (sqrt(sqr(fx - dx) + sqr(fy - dy)) < 12) then
          c[fx][fy] := 0;


    if area < 1 then break;
    mx := round(fill.MidX / area);
    my := round(fill.MidY / area);
    area := 0;
    ad := 0;
    maxdist := 0;
     for fy := Fill.y1 to Fill.y2 do
       for fx := Fill.x1 to Fill.x2 do
        begin
          if (c[fx][fy] = clLime) then
          begin
            for i := 0 to 3 do
             if (c[fx + ax[i]][fy + ay[i]] = 0) then
              begin
              dist := round(sqrt(sqr(mx - fx) + sqr(my - fy)));
               ad := ad + dist;
               if (maxdist < dist) then
                 maxdist := dist;
               inc(area);
               c[fx][fy] := $CCFF;
               break;
             end;
          end;
       end;

      if area < 1 then exit;
      ad := round(ad / area);
      // Make corners blue
       for fy := Fill.y1 to Fill.y2 do
         for fx := Fill.x1 to Fill.x2 do
         if (c[fx][fy] > 0) then
           if (sqrt(sqr(mx - fx) + sqr(my - fy)) >= ad) then
            c[fx][fy] := clblue;

    // Fill In corners
     for fy := Fill.y1 to Fill.y2 do
      for fx := Fill.x1 to Fill.x2 do
       if (c[fx][fy] = clblue) and (not(b[fx][fy])) then
        for i := 0 to 7 do
         if (c[fx + ax[i]][fy + ay[i]] <> 0) then
         begin
           c[fx + ax[i]][fy + ay[i]] := clblue;
           b[fx + ax[i]][fy + ay[i]] := true;
         end;

     cornercount := 0;
     bgColor := clblue;
     fillcolor := clpurple;
     FillInfo := false;
     bc := 0;
     mx := 0;
     my := 0;
     dist := 0;
    for fy := Fill.y1 to Fill.y2 do
      for fx := Fill.x1 to Fill.x2 do
      begin
       if (c[fx][fy] = clblue) then
       begin
         area := 0;
         ffillbg(fx, fy);
       if (area > 1) then
        inc(cornercount)
       else
         inc(bc);
      end;

      if (a[fx][fy] = 255) then
      begin
       mx := mx + fx;
       my := my + fy;
       inc(dist);
      end;
    end;



      if (bc > 0) then break;
      greenarea := 0;
    for fy := Fill.y1 to Fill.y2 do
      for fx := Fill.x1 to Fill.x2 do
       if (c[fx][fy] = cllime) then
        inc(greenarea);

        (* just in case, sometimes the 4 feather can by in the way *)
      if (cornercount = 1) and (greenarea < 5) and (maxdist > 12) then
          tailfound := 1
     else
      if (cornercount = 2) and (greenarea < 11) and (maxdist > 11) then
        tailfound := 2
     else
       if (cornercount = 3) and (greenarea > 9) and (maxdist > 10)  then
         tailfound := 3
     else
       if (cornercount > 3) then
         tailfound := 4;


      if (tailfound = tailsize) then
       begin
        result := true;
         fill.MidX := round(mx / dist);
         fill.MidY := round(my / dist);
        exit;
       end;
     end;
   // exit;
   end;
end;






function forest_FindPheasant(var px, py: Integer; TailSize: Integer; ClientHDC: HDC): Boolean;  register;
var
  BMP: TBitmap;
  Line: PRGB32Array;
  x, y, i, count: Integer;
  Hue, Lum, srgb, brgb: extended;


function RGBMin: Integer;
begin
  Result := Min(Min(Line[x].r, Line[x].g), Line[x].b);
end;

function RGBMax: Integer;
begin
  Result := Max(Max(Line[x].r, Line[x].g), Line[x].b);
end;

procedure Maskit;
begin
    sRGB := RGBMin / 255;
    bRGB := RGBMax / 255;
    Hue := 0.0;
    if (not(sRGB = bRGB)) then
    begin
       if (Line[x].r = bRGB) then
       Hue := (Line[x].g - Line[x].b) / (bRGB - sRGB)
     else if (Line[x].g = bRGB) then
       Hue := 2.0 + (Line[x].b - Line[x].r) / (bRGB - sRGB)
     else Hue := 4.0 + (Line[x].r - Line[x].g) / (bRGB - sRGB);
          Hue := Hue / 6.0;
        if (Hue < 0.0) then Hue := Hue + 1;
     end;

   if (Hue > 15.0) and (Hue < 19.0)then
   begin
     Lum := (srgb + brgb) / 2;
     if (lum > 0.22) then
       c[x][y] := clred;
   end;

   if (Hue > 20.0) and (Hue < 21.0) then
   begin
     if (a[x][y] > 7000000) then
     c[x][y] := clred
   else
     c[x][y] := clblue;
   end;

end;


begin
try
  w := 510; h := 333;
  Bmp := TBitmap.Create;
  Bmp.Width := w;
  Bmp.Height:= h;
  Bmp.PixelFormat := pf32bit;
  SetLength(c, w + 1, h + 1);
  SetLength(a, w + 1, h + 1);
  SetLength(b, w + 1, h + 1);
  //SetLength(b, w + 1, h + 1);
  bitsize := 7;
  BitBlt(Bmp.Canvas.Handle, 0, 0, w, h, ClientHDC, 4, 4, SRCCOPY);
  Result := False;

  for y := 4 to h-4 do
  begin
    Line := bmp.ScanLine[y];
   for x := 4 to w-2 do
   begin
     a[x][y] := RGB(Line[x].R, Line[x].G, Line[x].B);;
     c[x][y] := 0;
     Maskit;
     a[x][y] := c[x][y];
     b[x][y] := false;
   end;
 end;

 // Fill Pixels
for y := 4 to h - 4 do
 for x := 4 to w - 4 do
 if (a[x][y] = 0) then
  begin
   count := 0;
   for i := 0 to 3 do
    begin
    if (a[x + ax[i]][y + ay[i]] = clred) then
    inc(count);
     if (count > 2) then
      c[x][y] := clred;
    end;
 end;


case TailSize of
 1, 2, 3, 4: Result := FindTail234(TailSize);
end;

 if (Result) then
  begin
    px := fill.midx;
    py := fill.Midy;
  end;


finally
    Bmp.Free;

end;

end;
        }
{
function pillory_solvequestion(var px, py: Integer; var Canvas: Tcanvas; ClientHDC: HDC): Boolean;  register;
var
  BMP: TBitmap;
  Line: PRGB32Array;
  x, y, maxarea, mx, my: Integer;
  Hue, Lum, srgb, brgb: extended;
  mir: record
         maxparam, cornercount, mx, my: Integer;
    end;

// 205. 205


function RGBMin: Integer;
begin
  Result := Min(Min(Line[x].r, Line[x].g), Line[x].b);
end;

function RGBMax: Integer;
begin
  Result := Max(Max(Line[x].r, Line[x].g), Line[x].b);
end;

procedure Maskit;
begin
    sRGB := RGBMin / 255;
    bRGB := RGBMax / 255;
    Hue := 0.0;
    if (not(sRGB = bRGB)) then
    begin
       if (Line[x].r = bRGB) then
       Hue := (Line[x].g - Line[x].b) / (bRGB - sRGB)
     else if (Line[x].g = bRGB) then
       Hue := 2.0 + (Line[x].b - Line[x].r) / (bRGB - sRGB)
     else Hue := 4.0 + (Line[x].r - Line[x].g) / (bRGB - sRGB);
          Hue := Hue / 6.0;
        if (Hue < 0.0) then Hue := Hue + 1;
     end;

     if (Hue < 18.0) or (Hue > 20.0) then c[x][y] := 0
     else
     begin
       Lum := (srgb + brgb) / 2;
       if Lum > 0.20 then
       c[x][y] := 0 else c[x][y] := clwhite;
     end;


end;


begin
try
  w := 510; h := 333;
  Bmp := TBitmap.Create;
  Bmp.Width := w;
  Bmp.Height:= h;
  Bmp.PixelFormat := pf32bit;
  SetLength(c, w + 1, h + 1);

  bitsize := 7;
  dec(w); dec(h);
  Result := False;

  BitBlt(Bmp.Canvas.Handle, 0, 0, w + 1, h + 1, ClientHDC, 4, 4, SRCCOPY);

  for y := 0 to h do
  begin
    Line := bmp.ScanLine[y];
     for x := 0 to w do
      begin
        c[x][y] := RGB(Line[x].r, Line[x].g, Line[x].b);
        MaskIt;
        if (x < 40) then
            c[x][y] := 0;
      end;
  end;

  bgcolor := clwhite;
  fillcolor := clred;
  maxarea := 0;
  mx := 0; my := 0;
 for y := 5 to 205 do
   for x := 5 to 205 do
    if (c[x][y] = clwhite) then
     begin
       area := 0;
         FFillBg(x, y);
      if (maxarea < area) then
      begin
         mx := x;
         my := y;
         maxarea := area;
      end;
     end;

  bgcolor := clred;
  fillcolor := clwhite;
  FillInfo := True;
  FFillBg(mx, my);


 for y := 0 to h do
   for x := 0 to w do
    Canvas.Pixels[x, y] := c[x][y];


finally
    Bmp.Free;

end;

end;    }


//********************************
//  Change this accordingly to your function count

function GetFunctionCount(): Integer; stdcall; export;
begin
  Result := 4;
end;

//*******************************
//  Change this accordingly to your function definitions

function GetFunctionCallingConv(x : integer) : integer; stdcall;
begin
  result := cv_Register;
end;

function GetFunctionInfo(x: Integer; var ProcAddr: Pointer; var ProcDef: PChar): Integer; stdcall;
begin
  case x of
    0:
      begin
        ProcAddr := @Leo_AnalyzeGraveStone;
        StrPCopy(ProcDef, 'function Leo_AnalyzeGraveStone(var StoneName: PChar; ImageClient: TTarget_Exported): Boolean;');
      end;
   1:
      begin
        ProcAddr := @Leo_AnalyzeCoffin;
        StrPCopy(ProcDef, 'function Leo_AnalyzeCoffin(var StoneName: PChar; ImageClient: TTarget_Exported): Boolean;');
      end;

    2: begin
         ProcAddr := @Quiz_AnalyzeQuiz;
        StrPCopy(ProcDef, 'function Quiz_AnalyzeQuiz(ImageClient: TTarget_Exported; var objx, objy: Integer; var nameresult: PChar): Boolean;');
       end;
{    3: begin
         ProcAddr := @Certer_CountCerterPixels;
        StrPCopy(ProcDef, 'procedure Certer_CountCerterPixels(Canvas: TCanvas; width, height: Integer; var wi, hi: integer);');
      end;

    4: begin
         ProcAddr := @Certer_DistinguishPicture;
         StrPCopy(ProcDef, 'function Certer_DistinguishPicture(Canvas: TCanvas; var Item: string; width, height: Integer; Debug: Boolean): Boolean;');
      end;

    5: begin
         ProcAddr := @forest_FindPheasant;
         StrPCopy(ProcDef, 'function forest_FindPheasant(var px, py: Integer; TailSize: Integer; ClientHDC: HDC): Boolean;');
       end;

    6: begin
         ProcAddr := @pillory_solvequestion;
         StrPCopy(ProcDef, 'function pillory_solvequestion(var px, py: Integer; var Canvas: Tcanvas; ClientHDC: HDC): Boolean;');
       end;      }


  else
    x := -1;
  end;
  Result := x;
end;

exports GetFunctionCount;
exports GetFunctionInfo;
exports GetFunctionCallingConv;


begin
end.

