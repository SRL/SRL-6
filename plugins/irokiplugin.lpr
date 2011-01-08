{


 Iroki Plugin


After hours of hard work, I am proud to present this:

I want to say few words, i'm so happy that   develop this plugin, I learned
lots of new thinks, procedures, functions, etc... I made new friends, yeah it's
the most important :), and i lost too. ( i mean thet when nobody knows who I really
am they were trusting me and from time when i told who I am they are not trusting
me, that's sad :( ) - Manfromczech/Iroki

Special thanks goes to:
~ NaumanAkhlaQ: With out his help I'll newer made these solvers :)
~ tarajunky: With out his accounts I'll newer start working at these solvers
~ SKy Scripter: For his ScanFill(..); function

and to everyone who lended me accounts

I want to say only one word: THANKS.

}
library irokiplugin;

{$mode objfpc}{$H+}

uses
  Classes, math,sysutils
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
      ScrollMouse: procedure(target: pointer; x,y : integer; Lines : integer); stdcall;
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
  area, bitsize, bgcolor, fillcolor,
  w, h, x1, y1, x2, y2, xx, yy: Integer;
  animx1, animy1, animx2, animy2: integer;
  c, c1: array of array of Integer;
  b: array of array of Boolean;
  FillInfo: Boolean;


{

   Mime solver
   By: Iroki

}
function GetTickCount: DWord;
begin
  Result := DWord(Trunc(Now * 24 * 60 * 60 * 1000));
end;

function RGB(R, G, B : Byte) : integer; inline;
begin
  Result := R or (G shl 8) or (B Shl 16);
end;

type
  TIntArrArr = array of array of integer;
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
const
  Mime_Unknown = -1;
  Mime_Empty = 0;
  Mime_Think = 1;
  Mime_Dance = 2;
  Mime_Glass_Wall = 3;
  Mime_Lean_on_air = 4;
  Mime_Glass_box = 5;
  Mime_Laugh = 6;
  Mime_Climb_rope = 7;
  Mime_Cry = 8;

function Mime_AnalyzeAnimation(ImageClient : TTarget_Exported): Integer;  register;

var
  Line: PRGB32;
  Sx1, Sy1, Sx2, Sy2, ObjectArea, x, y, CoMax, CoMin,
  BlackArea, BMaxArea, BMinArea, sx, sy, a1, a2, b1, b2, BArea, FirstArea: integer;
  //Time: double;
  Obj: integer;
  RetData : TRetData;
//  TF: TextFile;

function SpotLight: boolean;
var
  x, y: integer;
begin
  Result := False;

  w := 500; h := 120;
  SetLength(c1, w + 1, h + 1);
  RetData := ImageClient.ReturnData(ImageClient.Target,4,4,w,h);

  FirstArea := 0;


  for y := 50 to 118 do
  begin
    Line := RetData.Ptr + y*RetData.RowLen;
    for x := 420 to 498 do
    begin
      c1[x][y] := RGB(Line[x].R, Line[x].G, Line[x].B);
      if (Line[x].R <> 0) then
        if (Line[x].R > 180) and (Line[x].G > 160) and (Line[x].B > 140) then
          inc(FirstArea);
    end;
  end;

  ImageClient.FreeReturnData(ImageClient.Target);

  if (FirstArea = 0) then Result := True;

end;


begin
  Result := Mime_Empty;
  a1 := 0; b1 := 0; a2 := 0; b2 := 0;
  CoMax := 0; CoMin := 999999; BMinArea := 0; BMaxArea := 999999;

  repeat
    w := 500; h := 120;
    SetLength(c1, w + 1, h + 1);

    RetData := ImageClient.ReturnData(ImageClient.Target,4,4,w,h);
    FirstArea := 0;

    for y := 50 to 118 do
    begin
      Line := RetData.Ptr + y*RetData.RowLen;
      for x := 420 to 498 do
      begin
        c1[x][y] := RGB(Line[x].R, Line[x].G, Line[x].B);
        if (Line[x].R <> 0) then
          if (Line[x].R > 180) and (Line[x].G > 160) and (Line[x].B > 140) then
            inc(FirstArea);
      end;
    end;

  ImageClient.FreeReturnData(ImageClient.Target);

  until (FirstArea <> 0);


//  QueryPerformanceFrequency(Freq);
//  QueryPerformanceCounter(Start);

  repeat
    w := 430; h := 210;
    SetLength(c, w + 1, h + 1);
    SetLength(b, w + 1, h + 1);
    RetData := ImageClient.ReturnData(ImageClient.Target,0,0,w,h);


    BlackArea := 0;

    Sx1 := 300; Sx2 := 410; Sy1 := 100; Sy2 := 200;

    for y := Sy1 to Sy2 do
    begin
      Line := RetData.Ptr + y*RetData.RowLen;
      for x := Sx1 to Sx2 do
      begin
        c[x][y] := RGB(Line[x].R, Line[x].G, Line[x].B);
        if (Line[x].R <> 0) then
        begin
          if (Line[x].R < 190) and (Line[x].G < 180) and (Line[x].B < 170) then
            begin
              c[x][y] := 0;
              b[x][y] := True;
              inc(BlackArea);
            end;
        end else
        begin
          c[x][y] := 0;
          b[x][y] := True;
          inc(BlackArea);
        end;
      end;
    end;


    ObjectArea := (11211 - BlackArea);

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

    for sx := Sx2 - 1 downto Sx1 + 1 do
      for sy := Sy1 + 1 to Sy2 - 1 do
      begin
        if (c[sx][sy] <> 0) then
        begin
          a2 := sx;
          break;
        end;
      end;

    for sx := Sx1 + 1 to Sx2 - 1 do
      for sy := Sy1 + 1 to Sy2 - 1 do
      begin
        if (c[sx][sy] <> 0) then
        begin
          a1 := sx;
          break;
        end;
      end;


    for sy := Sy2 - 1 downto Sy1 + 1 do
      for sx := Sx1 + 1 to Sx2 - 1 do
      begin
        if (c[sx][sy] <> 0) then
        begin
          b2 := sy;
          break;
        end;
      end;

    for sy := Sy1 + 1 to Sy2 - 1 do
      for sx := Sx1 + 1 to Sx2 - 1 do
      begin
        if (c[sx][sy] <> 0) then
        begin
          b1 := sy;
          break;
        end;
      end;


    BArea := (a2 - a1)*(b2 - b1);

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



    if (ObjectArea > CoMax) then
    begin
      CoMax := ObjectArea;
      BMaxArea := BArea;
    end;

    if (ObjectArea < CoMin) then
    begin
      CoMin := ObjectArea;
      BMinArea := BArea;
    end;

  ImageClient.FreeReturnData(ImageClient.Target);


  until SpotLight;

//  QueryPerformanceCounter(Stop);
//  Time := (1E3 * (Stop - Start) / Freq);


  Obj := Mime_Unknown;


  if ((BMaxArea - 30) < BMinArea) and
     InRange(CoMax, 100, 130) and InRange(CoMin, 50, 80) then Obj := Mime_Think
  else
  if (BMaxArea > 550) and
     InRange(CoMax, 110, 170) and (CoMin < 30) then Obj := Mime_dance
  else
  if InRange(BMaxArea, 340, 620) and (BMinArea < 330) and
     InRange(CoMax, 90, 120) and InRange(CoMin, 30, 60) then Obj := Mime_glass_wall
  else
  if InRange(BMaxArea, 390, 520) and InRange(BMinArea, 240, 400) and
     InRange(CoMax, 90, 130) and InRange(CoMin, 30, 70) then Obj := Mime_lean_on_air
  else
  if InRange(BMaxArea, 300, 600) and InRange(BMinArea, 400, 610) and
     InRange(CoMax, 80, 115) and InRange(CoMin, 30, 65) then Obj := mime_glass_box
  else
  if InRange(BMaxArea, 250, 350) and InRange(BMinArea, 110, 180) and
     InRange(CoMax, 120, 170) and InRange(CoMin, 25, 50) then Obj := Mime_laugh
  else
  if InRange(CoMax, 90, 120) and (CoMin < 40) then Obj := Mime_climb_rope
  else
  if InRange(BMaxArea, 400, 600) and (BMinArea < 110) and
     InRange(CoMax, 70, 120) and (CoMin < 30) then Obj := mime_cry;

  Result := Obj;

//   {if (Result = 'unknow') then } Result := (Obj + {' Lum ' + FloatToStr(Lum) + }' BMax: '+ IntToStr(BMaxArea) + ' BMin: ' + IntToStr(BMinArea) + ' ColoredMax: '+ IntToStr(CoMax) + ' ColoredMin: '+ IntToStr(CoMin));
//   Result := Result  + ' Time: ' + (IntToStr(round(Time)));

end;

{

   Mr.Mordaut plugin
   By: Iroki

}


function Mordaut_GetSlotNr(ScanningTime: Extended; ImageClient : TTarget_Exported): integer;  Register;

var
  Line: PRGB32;
  Sx1, Sy1, Sx2, Sy2, x, y, sx, sy, a1, a2, b1, b2, Slot, i: integer;
  Start, Stop, Freq: int64;
  ObjToFind: string;
  Obj: array of string;
  Lum: array of extended;
  CoMax: array of Integer;
  CoMin: array of Integer;
  BMaxArea: array of Integer;
  BMinArea: array of Integer;
  BArea: array of Integer;
  BlackArea: array of Integer;
  ObjectArea: array of Integer;
  cM: array of array of array of Integer;
  bM: array of array of array of Boolean;
  RetData : TRetData;

begin
  SetLength(Obj, 7);
  SetLength(Lum, 7);
  SetLength(CoMax, 7);
  SetLength(CoMin, 7);
  SetLength(BMaxArea, 7);
  SetLength(BMinArea, 7);
  SetLength(BArea, 7);
  SetLength(BlackArea, 7);
  SetLength(ObjectArea, 7);

  for Slot := 0 to 6 do
  begin
    CoMax[Slot] := 0; CoMin[Slot] := 2000; BMaxArea[Slot] := 0; BMinArea[Slot] := 0;
    BArea[Slot] := 0;
  end;

  start := GetTickCount;

  Sx1 := 0; Sy1 := 0; Sx2 := 0; Sy2 := 0; a1 := 0; a2 := 0; b1 := 0; b2 := 0;
  repeat

    w := 456; h := 291;
    SetLength(cM, w + 1, h + 1, 7);
    SetLength(bM, w + 1, h + 1, 7);
    RetData := ImageClient.ReturnData(ImageClient.Target,0,0,w,h);

    for Slot := 0 to 6 do
    begin
      BlackArea[Slot] := 0;
    //////////////////////


{
              Slots:
 _________________________________
|   ______ ______ ______          |
|  |      |      |      |         |
|  |  0   |  1   |  2   |         |
|  |______|______|______|         |
|                                 |
|        What comes next?         |
|   ______ ______ ______ ______   |
|  |      |      |      |      |  |
|  |  3   |  4   |  5   |  6   |  |
|  |______|______|______|______|  |
|_________________________________|
}

      case Slot of

        0, 1, 2: begin
          Sx1 := 55 + Slot*100;
          Sy1 := 45;
          Sx2 := Sx1 + 100;
          Sy2 := 145;
        end;

        3, 4, 5, 6: begin
          Sx1 := -245 + Slot*100;
          Sy1 := 190;
          Sx2 := Sx1 + 100;
          Sy2 := 290;
        end;
      end;



      for y := Sy1 to Sy2 do
      begin
        Line := RetData.Ptr + RetData.RowLen *y;
        for x := Sx1 to Sx2 do
        begin
          cM[x][y][Slot] := RGB(Line[x].R, Line[x].G, Line[x].B);
          if (Line[x].R <> 0) then
          begin
            if InRange(Line[x].R, 65, 95) then
             if InRange(Line[x].G, 80, 115) then
              if InRange(Line[x].B, 65, 95)then
              begin
                cM[x][y][Slot] := 0;
                bM[x][y][Slot] := True;
                inc(BlackArea[Slot]);
              end;
          end else
          begin
            cM[x][y][Slot] := 0;
            bM[x][y][Slot] := True;
            inc(BlackArea[Slot]);
          end;
        end;
      end;


      ObjectArea[Slot] := (10201 - BlackArea[Slot]);



      for sx := Sx2 - 1 downto Sx1 + 1 do
        for sy := Sy1 + 1 to Sy2 - 1 do
        begin
          if (cM[sx][sy][Slot] <> 0) then
          begin
            a2 := sx;
            break;
          end;
        end;

      for sx := Sx1 + 1 to Sx2 - 1 do
        for sy := Sy1 + 1 to Sy2 - 1 do
        begin
          if (cM[sx][sy][Slot] <> 0) then
          begin
            a1 := sx;
            break;
          end;
        end;


      for sy := Sy2 - 1 downto Sy1 + 1 do
        for sx := Sx1 + 1 to Sx2 - 1 do
        begin
          if (cM[sx][sy][Slot] <> 0) then
          begin
            b2 := sy;
            break;
          end;
        end;

      for sy := Sy1 + 1 to Sy2 - 1 do
        for sx := Sx1 + 1 to Sx2 - 1 do
        begin
          if (cM[sx][sy][Slot] <> 0) then
          begin
            b1 := sy;
            break;
          end;
        end;


      BArea[Slot] := (a2 - a1)*(b2 - b1);


      if (ObjectArea[Slot] > CoMax[Slot]) then
      begin
        CoMax[Slot] := ObjectArea[Slot];
        BMaxArea[Slot] := BArea[Slot];
      end;

      if (ObjectArea[Slot] < CoMin[Slot]) then
      begin
        CoMin[Slot] := ObjectArea[Slot];
        BMinArea[Slot] := BArea[Slot];
      end;

    //////////////
    end;

    ImageClient.FreeReturnData(ImageClient.Target);


  Until ((GetTickCount - Start) >= (ScanningTime * 1000));


  for Slot := 0 to 6 do
  begin
    if (CoMax[Slot] <> 0 ) then Lum[Slot] := (BMaxArea[Slot]/CoMax[Slot]);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~     Objects database     ~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Obj[Slot] := 'unknow';
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (Slot = 0) then
    begin

      if InRange(Lum[Slot], 1.3, 1.9) and InRange(BMaxArea[Slot], 700, 1200) and InRange(BMinArea[Slot], 340, 650) and InRange(CoMax[Slot], 580, 730)
          and InRange(CoMin[Slot], 300, 460) then Obj[Slot] := 'Q18';  // Boots

      if InRange(Lum[Slot], 1.35, 1.9) and InRange(BMaxArea[Slot], 100, 1350) and InRange(BMinArea[Slot], 300, 900) and InRange(CoMax[Slot], 700, 775)
          and InRange(CoMin[Slot], 115, 270) then Obj[Slot] := 'Q03';  // Thieve mask

      if InRange(Lum[Slot], 2.7, 4.9) and InRange(BMaxArea[Slot], 800, 1400) and InRange(BMinArea[Slot], 0, 160) and InRange(CoMax[Slot], 280, 360)
          and InRange(CoMin[Slot], 20, 80) then Obj[Slot] := 'Q02';  // Scimitar
    end;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (Slot = 1) then
    begin

      if InRange(Lum[Slot], 1.0, 1.5) and InRange(BMaxArea[Slot], 800, 1200) and InRange(BMinArea[Slot], 120, 250) and InRange(CoMax[Slot], 750, 820)
        and InRange(CoMin[Slot], 60, 200) then Obj[Slot] := 'Q20';   // Wooden shield

      if InRange(Lum[Slot], 1.5, 2.8) and InRange(BMaxArea[Slot], 1000, 1550) and InRange(BMinArea[Slot], 200, 450) and InRange(CoMax[Slot], 500, 670)
        and InRange(CoMin[Slot], 180, 320) then Obj[Slot] := 'Q19';   // Ore

      if InRange(Lum[Slot], 1.4, 2.2) and InRange(BMaxArea[Slot], 820, 1000) and InRange(BMinArea[Slot], 320, 700) and InRange(CoMax[Slot], 440, 540)
          and InRange(CoMin[Slot], 250, 330) then Obj[Slot] := 'Q17';   // Full helmet

      if InRange(Lum[Slot], 0.95, 1.45) and InRange(BMaxArea[Slot], 1000, 1400) and InRange(BMinArea[Slot], 450, 700) and InRange(CoMax[Slot], 900, 1100)
          and InRange(CoMin[Slot], 440, 600) then Obj[Slot] := 'Q16';   // Cake

      if InRange(Lum[Slot], 0.9, 1.4) and InRange(BMaxArea[Slot], 250, 380) and InRange(BMinArea[Slot], 220, 300) and InRange(CoMax[Slot], 240, 320)
          and InRange(CoMin[Slot], 150, 200) then Obj[Slot] := 'Q15';   // Garlic

      if InRange(Lum[Slot], 1.2, 4.0) and InRange(BMaxArea[Slot], 200, 560) and InRange(BMinArea[Slot], 20, 360) and InRange(CoMax[Slot], 130, 170)
          and InRange(CoMin[Slot], 10, 120) then Obj[Slot] := 'Q13';   // Shrimp

      if InRange(Lum[Slot], 1.4, 1.7) and InRange(BMaxArea[Slot], 510, 610) and InRange(BMinArea[Slot], 290, 410) and InRange(CoMax[Slot], 330, 410)
          and InRange(CoMin[Slot], 210, 260) then Obj[Slot] := 'Q11';   // Strawberry

      if InRange(Lum[Slot], 1.15, 1.4) and InRange(BMaxArea[Slot], 1150, 1300) and InRange(BMinArea[Slot], 380, 520) and InRange(CoMax[Slot], 900, 950)
          and InRange(CoMin[Slot], 380, 460) then Obj[Slot] := 'Q09';   // Fire rune

      if InRange(Lum[Slot], 1.45, 2.4) and InRange(BMaxArea[Slot], 700, 1200) and InRange(BMinArea[Slot], 0, 70) and InRange(CoMax[Slot], 465, 515)
          and InRange(CoMin[Slot], 0, 50) then Obj[Slot] := 'Q01';   // White approw

      if InRange(Lum[Slot], 1.40, 2.2) and InRange(BMaxArea[Slot], 940, 1310) and InRange(BMinArea[Slot], 680, 1000) and InRange(CoMax[Slot], 560, 640)
          and InRange(CoMin[Slot], 300, 360) then Obj[Slot] := 'Q06';   // Watering can

      if InRange(Lum[Slot], 1.5, 1.9) and InRange(BMaxArea[Slot], 1150, 1380) and InRange(BMinArea[Slot], 200, 500) and InRange(CoMax[Slot], 720, 790)
          and InRange(CoMin[Slot], 200, 360) then Obj[Slot] := 'Q07';   // Bar
    end;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (Slot = 2) then
    begin

      if InRange(Lum[Slot], 1.3, 2.9) and InRange(BMaxArea[Slot], 1100, 2300) and InRange(BMinArea[Slot], 390, 900) and InRange(CoMax[Slot], 770, 870)
          and InRange(CoMin[Slot], 250, 460) then Obj[Slot] := 'Q14';   // Monkfish

      if InRange(Lum[Slot], 1.0, 1.5) and InRange(BMaxArea[Slot], 800, 1200) and InRange(BMinArea[Slot], 120, 250) and InRange(CoMax[Slot], 750, 820)
          and InRange(CoMin[Slot], 60, 200) then Obj[Slot] := 'Q12';   // Wooden shield

      if InRange(Lum[Slot], 1.0, 1.3) and InRange(BMaxArea[Slot], 500, 580) and InRange(BMinArea[Slot], 120, 280) and InRange(CoMax[Slot], 420, 490)
          and InRange(CoMin[Slot], 35, 90) then Obj[Slot] := 'Q10';   // Rum

      if InRange(Lum[Slot], 2.7, 4.65) and InRange(BMaxArea[Slot], 770, 1250) and InRange(BMinArea[Slot], 200, 400) and InRange(CoMax[Slot], 250, 300)
          and InRange(CoMin[Slot], 70, 140) then Obj[Slot] := 'Q04';   // Crossbow

      if InRange(Lum[Slot], 1.75, 2.9) and InRange(BMaxArea[Slot], 200, 360) and InRange(BMinArea[Slot], 50, 150) and InRange(CoMax[Slot], 120, 140)
          and InRange(CoMin[Slot], 50, 70) then Obj[Slot] := 'Q05';   // Candle

      if InRange(Lum[Slot], 3.1, 4.0) and InRange(BMaxArea[Slot], 1300, 1700) and InRange(BMinArea[Slot], 80, 120) and InRange(CoMax[Slot], 380, 470)
          and InRange(CoMin[Slot], 55, 95) then Obj[Slot] := 'Q08';   // Holy symbol
    end;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if InRange(Slot, 3, 6) then
    begin

      if InRange(Lum[Slot], 1.2, 1.8) and InRange(BMaxArea[Slot], 1000, 1500) and InRange(BMinArea[Slot], 150, 280) and InRange(CoMax[Slot], 800, 870)
          and InRange(CoMin[Slot], 50, 150) then Obj[Slot] := 'Q20';   // Kiteshield

      if InRange(Lum[Slot], 1.5, 1.9) and InRange(BMaxArea[Slot], 1150, 1380) and InRange(BMinArea[Slot], 200, 500) and InRange(CoMax[Slot], 720, 790)
          and InRange(CoMin[Slot], 200, 360) then Obj[Slot] := 'Q19';   // Bar

      if InRange(Lum[Slot], 1.3, 2.0) and InRange(BMaxArea[Slot], 1020, 1300) and InRange(BMinArea[Slot], 380, 670) and InRange(CoMax[Slot], 650, 750)
          and InRange(CoMin[Slot], 300, 470) then Obj[Slot] := 'Q17';   // Platebody

      if InRange(Lum[Slot], 1.1, 1.35) and InRange(BMaxArea[Slot], 1150, 1350) and InRange(BMinArea[Slot], 400, 600) and InRange(CoMax[Slot], 950, 1050)
          and InRange(CoMin[Slot], 300, 370) then Obj[Slot] := 'Q16';   // Apple pie

      if InRange(Lum[Slot], 1.05, 2.2) and InRange(BMaxArea[Slot], 350, 1200) and InRange(BMinArea[Slot], 350, 1200) and InRange(CoMax[Slot], 400, 700)
          and InRange(CoMin[Slot], 70, 500) then Obj[Slot] := 'Q15';   // Pineapple

      if InRange(Lum[Slot], 1.9, 3.1) and InRange(BMaxArea[Slot], 700, 1100) and InRange(BMinArea[Slot], 150, 310) and InRange(CoMax[Slot], 330, 420)
          and InRange(CoMin[Slot], 50, 150) then Obj[Slot] := 'Q14';   // Trout

      if InRange(Lum[Slot], 3.0, 4.9) and InRange(BMaxArea[Slot], 1050, 1600) and InRange(BMinArea[Slot], 40, 170) and InRange(CoMax[Slot], 310, 380)
          and InRange(CoMin[Slot], 30, 100) then Obj[Slot] := 'Q13';   // Swordfish

      if InRange(Lum[Slot], 1.4, 2.6) and InRange(BMaxArea[Slot], 1100, 2000) and InRange(BMinArea[Slot], 100, 300) and InRange(CoMax[Slot], 700, 810)
          and InRange(CoMin[Slot], 40, 200) then Obj[Slot] := 'Q12';   // Antidragon shield

      if InRange(Lum[Slot], 1.5, 2.65) and InRange(BMaxArea[Slot], 300, 620) and InRange(BMinArea[Slot], 10, 110) and InRange(CoMax[Slot], 140, 280)
          and InRange(CoMin[Slot], 20, 100) then Obj[Slot] := 'Q11';   // Berry's

      if InRange(Lum[Slot], 1.2, 1.45) and InRange(BMaxArea[Slot], 1100, 1300) and InRange(BMinArea[Slot], 380, 520) and InRange(CoMax[Slot], 880, 950)
          and InRange(CoMin[Slot], 400, 460) then Obj[Slot] := 'Q09';   // Earth rune

      if InRange(Lum[Slot], 1.05, 2.0) and InRange(BMaxArea[Slot], 320, 570) and InRange(BMinArea[Slot], 120, 270) and InRange(CoMax[Slot], 250, 300)
          and InRange(CoMin[Slot], 100, 170) then Obj[Slot] := 'Q08';   // Ring

      if InRange(Lum[Slot], 1.05, 1.35) and InRange(BMaxArea[Slot], 1050, 1300) and InRange(BMinArea[Slot], 500, 650) and InRange(CoMax[Slot], 950, 1050)
          and InRange(CoMin[Slot], 480, 580) then Obj[Slot] := 'Q01';   // Cake

      if InRange(Lum[Slot], 2.4, 4.0) and InRange(BMaxArea[Slot], 520, 1050) and InRange(BMinArea[Slot], 200, 800) and InRange(CoMax[Slot], 210, 280)
          and InRange(CoMin[Slot], 110, 190) then Obj[Slot] := 'Q02';   // Mace

      if InRange(Lum[Slot], 1.7, 2.6) and InRange(BMaxArea[Slot], 760, 1100) and InRange(BMinArea[Slot], 250, 450) and InRange(CoMax[Slot], 400, 480)
          and InRange(CoMin[Slot], 110, 190) then Obj[Slot] := 'Q03';   // Jeaster hat

      if InRange(Lum[Slot], 1.4, 8.0) and InRange(BMaxArea[Slot], 300, 1250) and InRange(BMinArea[Slot], 0, 200) and InRange(CoMax[Slot], 140, 195)
          and InRange(CoMin[Slot], 0, 60) then Obj[Slot] := 'Q04';   // Longbow

      if InRange(Lum[Slot], 1.2, 1.75) and InRange(BMaxArea[Slot], 600, 800) and InRange(BMinArea[Slot], 320, 610) and InRange(CoMax[Slot], 400, 600)
          and InRange(CoMin[Slot], 200, 310) then Obj[Slot] := 'Q05';   // Bullseye lataren

      if InRange(Lum[Slot], 2.3, 3.3) and InRange(BMaxArea[Slot], 720, 1000) and InRange(BMinArea[Slot], 60, 160) and InRange(CoMax[Slot], 280, 340)
          and InRange(CoMin[Slot], 45, 100) then Obj[Slot] := 'Q06';   // Gardening trowel

      if InRange(Lum[Slot], 3.5, 5.4) and InRange(BMaxArea[Slot], 1020, 1750) and InRange(BMinArea[Slot], 95, 260) and InRange(CoMax[Slot], 270, 340)
          and InRange(CoMin[Slot], 70, 160) then Obj[Slot] := 'Q07';   // Pickaxe
    end;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  end;

  ObjToFind := 'unknow';
  Result := (0);

  for i := 0 to 2 do
    if (Obj[i] <> 'unknow') then ObjToFind := Obj[i];

  if (ObjToFind = 'Q10') then ObjToFind := 'Q08';
  if (ObjToFind = 'Q18') then ObjToFind := 'Q15';

  if (ObjToFind <> 'unknow') then
  begin
    for i := 3 to 6 do
    begin
      if (Obj[i] = ObjToFind) then Result := i;
    end;
  end else Result := (0);


end;





const
  Q01 = 1;
  Q02 = 2;
  Q03 = 3;
  Q04 = 4;
  Q05 = 5;
  Q06 = 6;
  Q07 = 7;
  Q08 = 8;
  Q09 = 9;
  Q10 = 10;
  QUnknown = -1;
procedure SetSlotNr(var slots : integer; nr : integer);
begin
  slots := slots or (1 shl nr);
end;
procedure Mordaut_GetBigSlotNr(ScanningTime: Extended; QuestionType: Integer; ImageClient : TTarget_Exported; var ThaSlots :Integer)  register;

var
  RetData : TRetData;
  Line: PRGB32;
  Sx1, Sy1, Sx2, Sy2, x, y, sx, sy, a1, a2, b1, b2, Slot, i, slotscount, ScanningTries: integer;
  Start, Stop, Freq: int64;
  ObjToFind: string;
  Obj: array of integer;
  Lum: array of extended;
  CoMax: array of Integer;
  CoMin: array of Integer;
  BMaxArea: array of Integer;
  BMinArea: array of Integer;
  BArea: array of Integer;
  BlackArea: array of Integer;
  ObjectArea: array of Integer;
  IsNeckle: array of Integer;
  cM: array of array of array of Integer;


label Scanning;
begin
  SetLength(Obj, 16);
  SetLength(Lum, 16);
  SetLength(CoMax, 16);
  SetLength(CoMin, 16);
  SetLength(BMaxArea, 16);
  SetLength(BMinArea, 16);
  SetLength(BArea, 16);
  SetLength(BlackArea, 16);
  SetLength(ObjectArea, 16);
  ScanningTries := 0;
  SetLength(IsNeckle, 16);

  inc(ScanningTries);

  Scanning:
  ThaSlots := 0;
  slotscount := 0;
  inc(ScanningTries);
  for Slot := 0 to 14 do
  begin
    CoMax[Slot] := 0; CoMin[Slot] := 2000; BMaxArea[Slot] := 0; BMinArea[Slot] := 0;
    BArea[Slot] := 0; IsNeckle[Slot] := 0;
  end;

  start := GetTickCount;

  Sx1 := 0; Sy1 := 0; Sx2 := 0; Sy2 := 0; a1 := 0; a2 := 0; b1 := 0; b2 := 0;
  repeat

    w := 372; h := 297;
    SetLength(cM, w + 1, h + 1, 16);
    RetData := ImageClient.ReturnData(ImageClient.Target,0,0,w,h);

    for Slot := 0 to 14 do
    begin
      BlackArea[Slot] := 0;
    //////////////////////


{
              Slots:
 _________________________________
|   ____ ____ ____ ____ ____      |
|  |    |    |    |    |    | ~~~ |
|  | 0  | 1  | 2  | 3  | 4  | ~~~ |
|  |____|____|____|____|____| ~~~ |
|  |    |    |    |    |    |     |
|  | 5  | 6  | 7  | 8  | 9  |     |
|  |____|____|____|____|____|     |
|  |    |    |    |    |    |     |
|  | 10 | 11 | 12 | 13 | 14 |     |
|  |____|____|____|____|____|     |
|_________________________________|
}

      case Slot of

        0, 1, 2, 3, 4: begin
          Sx1 := 40 + Slot*67;
          Sy1 := 35;
          Sx2 := Sx1 + 63;
          Sy2 := 114;
        end;

        5, 6, 7, 8, 9: begin
          Sx1 := -295 + Slot*67;
          Sy1 := 126;
          Sx2 := Sx1 + 63;
          Sy2 := 205;
        end;

        10, 11, 12, 13, 14: begin
          Sx1 := -630 + Slot*67;
          Sy1 := 217;
          Sx2 := Sx1 + 63;
          Sy2 := 296;
        end;
      end;



      for y := Sy1 to Sy2 do
      begin
        Line := RetData.Ptr + RetData.RowLen * y;
        for x := Sx1 to Sx2 do
        begin
          cM[x][y][Slot] := RGB(Line[x].R, Line[x].G, Line[x].B);
          if (Line[x].R <> 0) then
          begin
           if (Line[x].R > 180) then
            if (Line[x].G > 200) then
            begin
              cM[x][y][Slot] := 0;
              inc(BlackArea[Slot]);
            end;
          end else
          begin
            cM[x][y][Slot] := 0;
            inc(BlackArea[Slot]);
          end;
        end;
      end;


      ObjectArea[Slot] := (4977 - BlackArea[Slot]);


      if ((QuestionType = Q02) or (QuestionType = Q06)) then
       if (IsNeckle[Slot] = 0) then
       begin
         for y := Sy1 to Sy2 do
         begin
           if (not(cM[Sx1 + 1][y][Slot] = 0)) then IsNeckle[Slot] := 1;
         end;
       end;





      for sx := Sx2 - 1 downto Sx1 + 1 do
        for sy := Sy1 + 1 to Sy2 - 1 do
        begin
          if (cM[sx][sy][Slot] <> 0) then
          begin
            a2 := sx;
            break;
          end;
        end;

      for sx := Sx1 + 1 to Sx2 - 1 do
        for sy := Sy1 + 1 to Sy2 - 1 do
        begin
          if (cM[sx][sy][Slot] <> 0) then
          begin
            a1 := sx;
            break;
          end;
        end;


      for sy := Sy2 - 1 downto Sy1 + 1 do
        for sx := Sx1 + 1 to Sx2 - 1 do
        begin
          if (cM[sx][sy][Slot] <> 0) then
          begin
            b2 := sy;
            break;
          end;
        end;

      for sy := Sy1 + 1 to Sy2 - 1 do
        for sx := Sx1 + 1 to Sx2 - 1 do
        begin
          if (cM[sx][sy][Slot] <> 0) then
          begin
            b1 := sy;
            break;
          end;
        end;


      BArea[Slot] := (a2 - a1)*(b2 - b1);


      if (ObjectArea[Slot] > CoMax[Slot]) then
      begin
        CoMax[Slot] := ObjectArea[Slot];
        BMaxArea[Slot] := BArea[Slot];
      end;

      if (ObjectArea[Slot] < CoMin[Slot]) then
      begin
        CoMin[Slot] := ObjectArea[Slot];
        BMinArea[Slot] := BArea[Slot];
      end;

    //////////////
    end;

    ImageClient.FreeReturnData(ImageClient.Target);

  Until ((GetTickCount - start) >= (ScanningTime * 1000));



  for Slot := 0 to 14 do
  begin
  if (CoMax[Slot] <> 0) then Lum[Slot] := (BMaxArea[Slot]/CoMax[Slot]);
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~     Objects database     ~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Obj[Slot] := QUnknown;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (QuestionType = Q01) then
    begin
      if InRange(Lum[Slot], 1.6, 1.9) and InRange(BMaxArea[Slot], 810, 1010) and InRange(BMinArea[Slot], 530, 700) and InRange(CoMax[Slot], 480, 600)
             and InRange(CoMin[Slot], 170, 290) then Obj[Slot] := Q01;  // beer

      if InRange(Lum[Slot], 1.9, 2.8) and InRange(BMaxArea[Slot], 630, 900) and InRange(BMinArea[Slot], 300, 670) and InRange(CoMax[Slot], 300, 360)
             and InRange(CoMin[Slot], 50, 150) then Obj[Slot] := Q01;  // cocktail

      if InRange(Lum[Slot], 1.5, 1.7) and InRange(BMaxArea[Slot], 1120, 1360) and InRange(BMinArea[Slot], 630, 910) and InRange(CoMax[Slot], 700, 870)
             and InRange(CoMin[Slot], 300, 550) then Obj[Slot] := Q01;   // cup of tea
    end;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (QuestionType = Q02) then
    begin
      if InRange(Lum[Slot], 1.5, 1.85) and InRange(BMaxArea[Slot], 1050, 1200) and InRange(BMinArea[Slot], 290, 550) and InRange(CoMax[Slot], 630, 710)
             and InRange(CoMin[Slot], 80, 210) then Obj[Slot] := Q02;   // pirate hat

      if InRange(Lum[Slot], 3.3, 4.2) and InRange(CoMax[Slot], 220, 280) and InRange(CoMin[Slot], -144, -130) and InRange(BMaxArea[Slot], 870, 1020)
             then Obj[Slot] := Q02;   // eye patch

      if InRange(Lum[Slot], 4.9, 8.5) and InRange(BMaxArea[Slot], 620, 1100) and InRange(BMinArea[Slot], 30, 190) and InRange(CoMax[Slot], 100, 170)
             and InRange(CoMin[Slot], -110, -10) and (IsNeckle[Slot] = 1) then Obj[Slot] := Q02;   // hook
    end;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (QuestionType = Q03) then
    begin
      if InRange(Lum[Slot], 2.6, 4.2) and InRange(BMaxArea[Slot], 370, 600) and InRange(BMinArea[Slot], 100, 210) and InRange(CoMax[Slot], 110, 170)
             and InRange(CoMin[Slot], -80, -10) then Obj[Slot] := Q03;  // ring

      if InRange(Lum[Slot], 4.1, 5.5) and InRange(BMaxArea[Slot], 1300, 1650) and InRange(BMinArea[Slot], 50, 180) and InRange(CoMax[Slot], 270, 350)
             and InRange(CoMin[Slot], -90, -40) then Obj[Slot] := Q03;  // holy symbol

      if InRange(Lum[Slot], 3.9, 7.2) and InRange(BMaxArea[Slot], 620, 920) and InRange(BMinArea[Slot], 30, 130) and InRange(CoMax[Slot], 110, 160)
             and InRange(CoMin[Slot], -100, -10) then Obj[Slot] := Q03;   // neckle
    end;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (QuestionType = Q04) then
    begin
      if InRange(BMinArea[Slot], 290, 500) and InRange(CoMax[Slot], 120, 180) and InRange(CoMin[Slot], -80, 0) then Obj[Slot] := Q04;   // crossbow

      if InRange(BMinArea[Slot], 0, 120) and InRange(CoMax[Slot], 10, 70) and InRange(CoMin[Slot], -144, -90) then Obj[Slot] := Q04;   // longbow

      if (Lum[Slot] > 5.8) and InRange(BMinArea[Slot], 0, 40) and InRange(CoMin[Slot], -144, -90) then Obj[Slot] := Q04;   // arrows
    end;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (QuestionType = Q05) then
    begin
      if InRange(Lum[Slot], 1.4, 2.1) and InRange(BMaxArea[Slot], 1050, 1500) and InRange(BMinArea[Slot], 600, 900) and InRange(CoMax[Slot], 680, 750)
             and InRange(CoMin[Slot], 220, 440) then Obj[Slot] := Q05;  // logs

      if InRange(Lum[Slot], 1.6, 2.1) and InRange(BMaxArea[Slot], 730, 820) and InRange(BMinArea[Slot], 320, 540) and InRange(CoMax[Slot], 380, 440)
             and InRange(CoMin[Slot], 160, 200) then Obj[Slot] := Q05;  // bullseye lantern

      if (BMaxArea[Slot] > 1600) and (BMinArea[Slot] > 1000) and (CoMax[Slot] > 1200)
             and (CoMin[Slot]> 450) then Obj[Slot] := Q05;   // tinderbox
    end;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (QuestionType = Q06) then
    begin
      if InRange(Lum[Slot], 4.9, 6.1) and InRange(BMaxArea[Slot], 790, 960) and InRange(BMinArea[Slot], -1, 100) and InRange(CoMax[Slot], 130, 180)
             and InRange(CoMin[Slot], -143, -70) then Obj[Slot] := Q06;   // battle axe

      if InRange(Lum[Slot], 4.4, 6.2) and InRange(BMaxArea[Slot], 1000, 1400) and InRange(BMinArea[Slot], 10, 140) and InRange(CoMax[Slot], 210, 260)
             and InRange(CoMin[Slot], -120, -50) and (IsNeckle[Slot] = 1) then Obj[Slot] := Q06;   // scimitar

      if InRange(BMinArea[Slot], -1, 60) and InRange(CoMax[Slot], -10, 60)
             and InRange(CoMin[Slot], -140, -100) and (IsNeckle[Slot] = 1) then Obj[Slot] := Q06;   // sword
    end;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (QuestionType = Q07) then
    begin
      if InRange(Lum[Slot], 1.2, 1.5) and InRange(BMaxArea[Slot], 1120, 1250) and InRange(BMinArea[Slot], 390, 550) and InRange(CoMax[Slot], 820, 920)
             and InRange(CoMin[Slot], 270, 370) then Obj[Slot] := Q07;  // fire rune

      if InRange(Lum[Slot], 1.2, 1.6) and InRange(BMaxArea[Slot], 1120, 1350) and InRange(BMinArea[Slot], 390, 550) and InRange(CoMax[Slot], 830, 940)
             and InRange(CoMin[Slot], 250, 370) then Obj[Slot] := Q07;  // water rune

      if InRange(CoMin[Slot], -130, -80) and (IsNeckle[Slot] = 1) then Obj[Slot] := Q07;   // staff
    end;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (QuestionType = Q08) then
    begin
      if InRange(Lum[Slot], 1.6, 2.3) and InRange(BMaxArea[Slot], 1030, 1450) and InRange(BMinArea[Slot], 520, 760) and InRange(CoMax[Slot], 510, 680)
             and InRange(CoMin[Slot], -50, 120) then Obj[Slot] := Q08;  // hemingway mask

      if InRange(Lum[Slot], 1.3, 1.65) and InRange(BMaxArea[Slot], 1050, 1250) and InRange(BMinArea[Slot], 740, 900) and InRange(CoMax[Slot], 690, 830)
             and InRange(CoMin[Slot], 400, 530) then Obj[Slot] := Q08;  // frog mask

      if InRange(Lum[Slot], 1.3, 1.75) and InRange(BMaxArea[Slot], 950, 1200) and InRange(BMinArea[Slot], 380, 650) and InRange(CoMax[Slot], 650, 750)
             and InRange(CoMin[Slot], 80, 320) then Obj[Slot] := Q08;   // mime mask

    end;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (QuestionType = Q09) then
    begin
      if InRange(Lum[Slot], 2.0, 3.1) and InRange(BMaxArea[Slot], 700, 1020) and InRange(BMinArea[Slot], 200, 620) and InRange(CoMax[Slot], 310, 380)
             and InRange(CoMin[Slot], -10, 60) then Obj[Slot] := Q09;  // jester hat

      if InRange(Lum[Slot], 1.1, 2.0) and InRange(BMaxArea[Slot], 1000, 1400) and InRange(BMinArea[Slot], 430, 580) and InRange(CoMax[Slot], 690, 760)
             and InRange(CoMin[Slot], 80, 150) then Obj[Slot] := Q09;  // lederhosen hat

      if InRange(Lum[Slot], 1.5, 1.85) and InRange(BMaxArea[Slot], 1050, 1200) and InRange(BMinArea[Slot], 290, 550) and InRange(CoMax[Slot], 630, 710)
             and InRange(CoMin[Slot], 80, 210) then Obj[Slot] := Q09;   // pirate hat
    end;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (QuestionType = Q10) then
    begin
      if InRange(Lum[Slot], 5.9, 11.0) and InRange(BMaxArea[Slot], 700, 1250) and InRange(BMinArea[Slot], 15, 220) and InRange(CoMax[Slot], 80, 140)
             and InRange(CoMin[Slot], -130, -70) then Obj[Slot] := Q10;  // harpoon

      if InRange(Lum[Slot], 2.5, 4.5) and InRange(BMaxArea[Slot], 700, 1200) and InRange(BMinArea[Slot], 120, 300) and InRange(CoMax[Slot], 220, 290)
             and InRange(CoMin[Slot], -80, -20) then Obj[Slot] := Q10;  // fish
    end;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



    if (Obj[Slot] = QuestionType) then
    begin
      SetSlotNr(ThaSlots,slot);
      inc(slotscount);
    end;



  end;

  if ((slotscount <> 3) and (ScanningTries < 10)) then goto Scanning;
  if (ScanningTries >= 4) then
  begin
    ThaSlots:= 0;
    SetSlotNr(ThaSlots,random(5));
    SetSlotNr(ThaSlots,4 + Random(5));
    SetSlotNr(ThaSlots,9 + Random(5));
  end;
end;

{

   Leo solver
   By: Iroki

}
const
  Coffin_error = -1;
  Coffin_woodcutting = 1;
  coffin_cooking = 2;
  coffin_crafting = 3;
  coffin_farming = 4;
  coffin_mining = 5;

function Leo_AnalyzeCoffin2(ImageClient : TTarget_Exported): Integer; Register;

type
  SlotBox = record
  Bx1, Bx2, By1, By2: integer;
  end;

var
  RetData : TRetData;
  Line: PRGB32;
  Bw, Bh, i, j, BigObjects, MedObjects: integer;
  k: byte;
  MBox: SlotBox;
  ColoredArea: array of integer;
  X: array of array of integer;


function BoxCoords(Box: byte): SlotBox;
var
  x1, y1, x2, y2: integer;
begin
  x1 := 0; y1 := 0; x2 := 0; y2 := 0;

  case Box of
    0..2: begin
            x1 := 140 + (Box * 83);
            y1 := 47;
            x2 := x1 + 83;
            y2 := y1 + 82;
          end;
    3..5: begin
            x1 := -109 + (Box * 83);
            y1 := 129;
            x2 := x1 + 83;
            y2 := y1 + 82;
          end;
    6..8: begin
            x1 := -358 + (Box * 83);
            y1 := 211;
            x2 := x1 + 83;
            y2 := y1 + 82;
          end;
  end;

  Result.Bx1 := x1;
  Result.By1 := y1;
  Result.Bx2 := x2;
  Result.By2 := y2;

end;


begin
  BigObjects := 0; MedObjects := 0;


  Bw := 389; Bh := 293;


  SetLength(X, Bw + 1, Bh + 1);
  SetLength(ColoredArea, 9);

  retdata := ImageClient.ReturnData(ImageClient.Target,4,4,bw,bh);



  for j := 49 to 292 do
  begin
    Line := RetData.Ptr + RetData.RowLen * j;
    for i := 140 to 389 do
    begin
      X[i][j] := RGB(Line[i].R, Line[i].G, Line[i].B);
      if (Line[i].R > 95) and (Line[i].G > 90) and (Line[i].B > 90) then
         X[i][j] := clRed;
    end;
  end;



  for k := 0 to 8 do
  begin
    MBox := BoxCoords(k);
    for i := MBox.Bx1 to MBox.Bx2 do
      for j := MBox.By1 to MBox.By2 do
        if (X[i][j] = clRed) then Inc(ColoredArea[k]);
  end;

  for k := 0 to 8 do
  begin
    if (ColoredArea[k] > 2000) then Inc(BigObjects);
    if InRange(ColoredArea[k], 700, 2000) then Inc(MedObjects);
  end;

  ImageClient.FreeReturnData(imageclient.Target);

  Result := Coffin_error;

  case BigObjects of
    1: Result := coffin_woodcutting;
    2: Result :=  coffin_cooking;
    3: Result :=  coffin_crafting;
  end;

  if Result = Coffin_error then
  case MedObjects of
    3: Result :=  coffin_farming;
    4: Result :=  coffin_mining;
  end;

//  Result := 'BigObjects: ' + IntToStr(BigObjects) + ' MedObjects: ' + IntToStr(MedObjects);
end;




function Leo_AnalyzeGraveStone2(ImageClient: TTarget_Exported): Integer; register;
var
  Retdata : TRetData;
  Line: PRGB32;
  Bw, Bh, i, j, Area: integer;
  X: array of array of integer;
  IsAxe, IsCooking: Boolean;

begin
  Result :=  coffin_error;
  Area := 0;
  IsAxe := False;
  IsCooking := False;

  Bw := 475; Bh := 210;
  SetLength(X, Bw + 1, Bh + 1);

  Retdata := ImageClient.ReturnData(ImageClient.Target,6,6,bw,bh);
  //BitBlt(Bmp.Canvas.Handle, 0, 0, Bw, Bh, ClientHDC, 6, 6, SRCCOPY);


  for j := 15 to Bh - 6 do
  begin
    Line := Retdata.Ptr + j * Retdata.RowLen;
    for i := 115 to Bw - 6 do
    begin
      X[i][j] := RGB(Line[i].R, Line[i].G, Line[i].B);

      if (j = 158) and (i = 179) then
        if (Line[i].R < 86) and (Line[i].G < 86) then IsAxe := True;


      if (j = 141) and (i = 412) then
        if (Line[i].R < 82) and (Line[i].G < 80) and (Line[i].G < 80)
          then IsCooking := True;


      if (Line[i].R > 95) and (Line[i].G > 95) and (Line[i].B > 95) then
      begin
        inc(Area);
        X[i][j] := clRed;
      end;
    end;
  end;



  if IsAxe then
    if ((X[235][161] = clRed) or (X[234][160] = clRed)) and ((X[235][159] = clRed) or (X[233][160] = clRed)) then
    begin if (Area > 1500) then Result :=  coffin_crafting; end else if (Area < 1200) then Result :=  coffin_woodcutting;


  if not IsAxe then
    if not((X[355][160] = clRed) and ((X[335][158] = clRed) or (X[336][161] = clRed))) then
      begin if  IsCooking then Result :=  coffin_cooking else Result :=  coffin_farming;
    end else Result :=  coffin_mining;

  ImageClient.FreeReturnData(ImageClient.Target);

//  Result := Result + ' ' + inttostr(Area);
end;

procedure ScanFill(x, y: Integer); Register;
var
   i: integer;
begin
  if (c[x][y] <> bgcolor) then exit;
  c[x][y] := fillcolor;
  b[x][y] := True;
  area := area + 1;
  xx := 0;
  yy := 0;

  xx := x + 1;
  while (xx < W) and (C[xx][y] = bgColor)and
  (not(B[xx][y])) do
  begin
    c[xx][y] := fillcolor;
    b[xx][y] := True;
    Area := area + 1;
    xx := xx + 1;
 //   if (animx1 < xx) then animx1 := xx;
   end;
  if (xx - x > 1) then ScanFill(xx, y);

  xx := x - 1;
  while (xx > 1) and (C[xx][y] = bgColor) and
  (not(B[xx][y])) do
  begin
    c[xx][y] := fillcolor;
    b[xx][y] := True;
    Area := area + 1;
    xx := xx - 1;
//    if (animx1 > xx) then animx1 := xx;
   end;
  if  (x - xx > 1) then ScanFill(xx, y);

  yy := y + 1;
  while (yy < H) and (C[x][yy] = bgColor) and
  (not(B[x][yy])) do
  begin
    c[x][yy] := fillcolor;
    b[x][yy] := True;
    Area := area + 1;
    yy := yy + 1;
//    if (animy1 < yy) then animy1 := yy;
   end;
  if (yy - y > 1) then ScanFill(x, yy);

  yy := y - 1;
  while (yy > 1) and (C[x][yy] = bgColor) and
  (not(B[x][yy])) do
  begin
    c[x][yy] := fillcolor;
    b[x][yy] := True;
    Area := area + 1;
    yy := yy - 1;
 //   if (animy2 > yy) then animy2 := yy;
   end;
  if (y - yy > 1) then ScanFill(x, yy);

  for i:= 0 to bitsize do
   if (x + ax[i] > 0) and (x + ax[i] < w) and
      (y + ay[i] > 0) and (y + ay[i] < h) then
       if (not(B[x + ax[i]][y + ay[i]])) and
       (c[x + ax[i]][y + ay[i]] = bgcolor) then
    ScanFill(x + ax[i], y + ay[i]);
end;


procedure FFillBg(x, y: Integer); Register;
var
   i: integer;
begin
  c[x][y] := fillcolor;
  area := area + 1;

  for i:= 0 to bitsize do
    if (x + ax[i] > 0) and (x + ax[i] < w) and
       (y + ay[i] > 0) and (y + ay[i] < h) then
    if (c[x + ax[i]][y + ay[i]] = bgcolor) then
    begin
      FFillBg(x + ax[i], y + ay[i]);
    end

end;


{

   Prison-Pete solver
   By: ManFromCzech

}

var
 a: array [1..9] of record
          x1, y1, x2, y2, Parts,
          Area, Parm, mx, my, Holes,
          MinDist:Integer;
        end;



const
  Pete_Unknown = -1;
  Pete_goat = 1;
  pete_cat = 2;
  pete_sheep = 3;
  pete_dog = 4;

function Pete_AnalyzeAnimal( var AnimalName: Integer; ImageClient : TTarget_Exported): Boolean; register;
var
  RetData : TRetData;
  x, y, MaxArea, Pixels, i,
  fx, fy, Holes, MinDist,
  mx, my, Dist, HistoArea: Integer;
  HG: array [0..1000] of Integer;
  Done: Boolean;
  st, lum1, lum2: Extended;
  Line: PRGB32;
label Lab1;
begin
  Result := False;
  AnimalName := Pete_Unknown;
  w := 460; h := 330;
  SetLength(c, w + 1, h + 1);
  SetLength(b, w + 1, h + 1);
  bitsize := 7;
  st := Now;
  Done := false;
  fx := 0; fy := 0;
  dec(w); dec(h);
repeat
  RetData := ImageClient.ReturnData(ImageClient.Target,60,20,w,h);
//  BitBlt(Bmp2.Canvas.Handle, 0, 0, w, h, ClientHDC, 60, 20, SRCCOPY);
  fillchar(HG, sizeof(HG), 0);

  for y := 0 to h do
  begin
//     Line := bmp2.ScanLine[y];
    line := RetData.Ptr + RetData.RowLen* y;

   for x := 0 to w do
   begin
     c[x][y] := RGB(Line[x].R, Line[x].G, Line[x].B);
     b[x][y] := false;
     if (Line[x].G <> 0) then
     begin
       Lum1 := (Line[x].G * 3);
       Lum2 := (Line[x].R + Line[x].B);
     end else c[x][y] := 0;
    if ((lum2 / lum1) < 1.2) then c[x][y] := 0;

  with Line[x] do
    inc(HG[round(Sqrt(R*R + G*G + B*B))]);

   end;
 end;

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

 for y := 5 to h-5 do
  for x := 5 to w-5 do
   if (c[x][y] <> 0) then
   begin
       if (x < x1) then x1 := x - 5;
       if (y < y1) then y1 := y;
       if (x > x2) then x2 := x + 5;
       if (y > y2) then y2 := y;
   end;
 if ((x2 - x1) >= 50) and ((y2 - y1) >= 30) then Done := True;
 Sleep(100);
 ImageClient.FreeReturnData(ImageClient.Target);
until (((Now - st) * 86400000) > 15000) or (Done);
 if (not(done)) then goto lab1;


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
     begin
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
  if (Pixels < 4000) then goto lab1;

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



 Holes := 0;
 BgColor := 0;
 FillColor := clpurple;
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


  if (Pixels > 22500) then AnimalName := pete_goat;
  if ((Pixels > 16000) and (Pixels < 22000)) then AnimalName := pete_cat;
  if ((Pixels > 15000) and (Pixels < 22000)) and (MinDist > 35) then AnimalName := pete_sheep;
  if ((Pixels > 12500) and (Pixels <= 16000)) and (MinDist > 10) then AnimalName := pete_dog;


  if (not(AnimalName = Pete_Unknown)) then
  begin
    Result := True;
    goto Lab1;
  end;

Lab1:

end;







function Pete_FindAnimal(var px, py: Integer; AnimalName: integer; ImageClient : TTarget_Exported): Boolean;  register;
var
  RetData : TretData;
  Line: PRGB32;
  x, y, BRPixels, BPixels, RPixels, minKol, maxKol, minArea, maxArea, kol, Xa, Ya, AB, BRRPP: Integer;
  Lum1, Lum2: extended;
  Found, FoundAnim, FoundAnimal: Boolean;



procedure CountBRPixels(var x1, y1, x2, y2: integer);
var
  a, b: integer;
begin
  BRPixels := 0;
  RPixels := 0;
  BPixels := 0;
  for b := (y1 + 1) to (y2 - 1) do
  begin
    for a := (x1 + 1) to (x2 - 1) do
    begin
      if (c[a][b] = clred) then inc(RPixels);
      if (c[a][b] = clred) and (c[a + 1][b] = 0) then inc(BRPixels);
      if (c[a][b] = clred) and (c[a - 1][b] = 0) then inc(BRPixels);
      if (c[a][b] = clred) and (c[a][b + 1] = 0) then inc(BRPixels);
      if (c[a][b] = clred) and (c[a][b - 1] = 0) then inc(BRPixels);
    end;
  end;
end;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

//Finding cat
procedure FindCat(var x1, y1, x2, y2: integer);
var
  x, y, z, v, how, value, rownr, lastrowvalue, tvalue, countvalue, testvalue, ones, twoes: integer;
  IsLongTail: boolean;
begin
  x := x1; y := y1; z := x2; v := y2;
  if ((z - x) >= ((v - y) + 15)) then how := 1 else if (((z - x) + 15) <= (v - y)) then how := 2 else how := 3;
  IsLongTail := False;

  if (how = 1)then
  begin
    rownr := 0;
    lastrowvalue := 1;
    countvalue := 0;
    ones := 0;
    twoes := 0;
    FoundAnimal := False;
    for x := x1 to z do
    begin
      value := 0;
      for y := y1 to v do
      begin
        if (c[x][y] = clred) then inc(value);
        b[x][y] := True;
      end;
      inc(rownr);
      tvalue := 0;
      if (value <= 5) and (value > 0) then tvalue := 1;
      if (value > 5) and (value < 20) then tvalue := 2;
      if not(tvalue <> 1) or not(tvalue <> 2) or not(tvalue <> 0) then
      begin
        if (lastrowvalue = tvalue) then
        begin
          inc(countvalue);
        end else
        begin
          if (countvalue <> 0) and (lastrowvalue <> 0) then
          begin
            if (countvalue > 2) or (lastrowvalue = 2) then
            begin
//              WriteLn(inttostr(lastrowvalue) + ' [' + inttostr(countvalue) + ']');
              if (lastrowvalue = 1) then inc(ones);
              if (lastrowvalue = 1) and (countvalue > 11) then IsLongTail := True;
              if (lastrowvalue = 2) then inc(twoes);
            end;
            countvalue := 1;
            testvalue := 0;
            lastrowvalue := tvalue;
          end;
        end;
      end;
    end;
    if (((ones < 3) and (ones > 0) and (twoes = 2)) or ((ones = 3) and (twoes = 2)) or ((ones = 3) and (twoes = 3)) or ((ones = 2) and (twoes = 3)) or ((ones = 1) and (twoes = 4))) and (IsLongTail) then
    begin
      px := x1 + Round((x2 - x1)/2);
      py := y1 + Round((y2 - y1)/2);
    end;
  end;

  if (how = 2) then
  begin
    rownr := 0;
    lastrowvalue := 1;
    countvalue := 0;
    ones := 0;
    twoes := 0;
    FoundAnimal := False;
    for y := y1 to v do
    begin
      value := 0;
      for x := x1 to z do
      begin
        if (c[x][y] = clred) then inc(value);
        b[x][y] := True;
      end;
      inc(rownr);
      tvalue := 0;
      if (value <= 5) and (value > 0) then tvalue := 1;
      if (value > 5) and (value < 20) then tvalue := 2;
      if not(tvalue <> 1) or not(tvalue <> 2) or not(tvalue <> 0) then
      begin
        if (lastrowvalue = tvalue) then
        begin
          inc(countvalue);
        end else
        begin
          if (countvalue <> 0) and (lastrowvalue <> 0) then
          begin
            if (countvalue > 2) or (lastrowvalue = 2) then
            begin
 //             WriteLn(inttostr(lastrowvalue) + ' [' + inttostr(countvalue) + ']');
              if (lastrowvalue = 1) then inc(ones);
              if (lastrowvalue = 1) and (countvalue > 11) then IsLongTail := True;
              if (lastrowvalue = 2) then inc(twoes);
            end;
            countvalue := 1;
            testvalue := 0;
            lastrowvalue := tvalue;
          end;
        end;
      end;
    end;
    if (((ones < 3) and (ones > 0) and (twoes = 2)) or ((ones = 3) and (twoes = 2)) or ((ones = 3) and (twoes = 3)) or ((ones = 2) and (twoes = 3)) or ((ones = 1) and (twoes = 4))) and (IsLongTail) then
    begin
      px := x1 + Round((x2 - x1)/2);
      py := y1 + Round((y2 - y1)/2);
    end;
  end;

  if (how = 3) then
  for y := y1 to v do
  for x := x1 to z do b[x][y] := True;

//  WriteLn('how: ' + inttostr(how));
end;


////////////////////////////////////////////////////////////////////////////////

//Finding dog
procedure FindDog(var x1, y1, x2, y2: integer);
var
  x, y, z, v, how, value, rownr, lastrowvalue, tvalue, countvalue, testvalue, ones, twoes: integer;
  animal: array of integer;
  IsDog1, IsDog2: boolean;
begin
  x := x1; y := y1; z := x2; v := y2;
  if ((z - x) >= ((v - y) + 15)) then how := 1 else if (((z - x) + 15) <= (v - y)) then how := 2 else how := 3;
  IsDog1 := False;
  IsDog2 := False;

  if (how = 1)then
  begin
    rownr := 0;
    lastrowvalue := 1;
    countvalue := 0;
    ones := 0;
    twoes := 0;
    FoundAnimal := False;
    for x := x1 to z do
    begin
      value := 0;
      for y := y1 to v do
      begin
        if (c[x][y] = clred) then inc(value);
        b[x][y] := True;
      end;
      inc(rownr);
      tvalue := 0;
      if (value <= 5) and (value > 0) then tvalue := 1;
      if (value > 5) and (value < 20) then tvalue := 2;
      if not(tvalue <> 1) or not(tvalue <> 2) or not(tvalue <> 0) then
      begin
        if (lastrowvalue = tvalue) then
        begin
          inc(countvalue);
        end else
        begin
          if (countvalue <> 0) and (lastrowvalue <> 0) then
          begin
            if (countvalue > 2) or (lastrowvalue = 2) then
            begin
//              WriteLn(inttostr(lastrowvalue) + ' [' + inttostr(countvalue) + ']');
              if (lastrowvalue = 1) then inc(ones);
              if (lastrowvalue = 1) and (countvalue > 10) then IsDog1 := True;
              if (lastrowvalue = 2) and (countvalue > 8) then IsDog2 := True;
              if (lastrowvalue = 2) then inc(twoes);
            end;
            countvalue := 1;
            testvalue := 0;
            lastrowvalue := tvalue;
          end;
        end;
      end;
    end;
    if (((ones = 4) and (twoes = 3)) or ((ones = 3) and (twoes = 3)) or ((ones = 3) and (twoes = 2)) or ((ones = 2) and (twoes = 3))) and (not(IsDog1)) and (not(Isdog2)) then
    begin
      px := x1 + Round((x2 - x1)/2);
      py := y1 + Round((y2 - y1)/2);
    end;
  end;

  if (how = 2) then
  begin
    rownr := 0;
    lastrowvalue := 1;
    countvalue := 0;
    ones := 0;
    twoes := 0;
    FoundAnimal := False;
    for y := y1 to v do
    begin
      value := 0;
      for x := x1 to z do
      begin
        if (c[x][y] = clred) then inc(value);
        b[x][y] := True;
      end;
      inc(rownr);
      tvalue := 0;
      if (value <= 5) and (value > 0) then tvalue := 1;
      if (value > 5) and (value < 20) then tvalue := 2;
      if not(tvalue <> 1) or not(tvalue <> 2) or not(tvalue <> 0) then
      begin
        if (lastrowvalue = tvalue) then
        begin
          inc(countvalue);
        end else
        begin
          if (countvalue <> 0) and (lastrowvalue <> 0) then
          begin
            if (countvalue > 2) or (lastrowvalue = 2) then
            begin
//              WriteLn(inttostr(lastrowvalue) + ' [' + inttostr(countvalue) + ']');
              if (lastrowvalue = 1) then inc(ones);
              if (lastrowvalue = 1) and (countvalue > 10) then IsDog1 := True;
              if (lastrowvalue = 2) and (countvalue > 8) then IsDog2 := True;
              if (lastrowvalue = 2) then inc(twoes);
            end;
            countvalue := 1;
            testvalue := 0;
            lastrowvalue := tvalue;
          end;
        end;
      end;
    end;
    if (((ones = 4) and (twoes = 3)) or ((ones = 3) and (twoes = 3)) or ((ones = 3) and (twoes = 2)) or ((ones = 2) and (twoes = 3))) and (not(IsDog1)) and (not(Isdog2)) then
    begin
      px := x1 + Round((x2 - x1)/2);
      py := y1 + Round((y2 - y1)/2);
    end;
  end;

end;

////////////////////////////////////////////////////////////////////////////////

//Finding goat
procedure FindGoat(var x1, y1, x2, y2: integer);
begin
  Area := 0;
  ScanFill(x, y);
  if (Area > 200) then
  begin
    px := x1 + Round((x2 - x1)/2);
    py := y1 + Round((y2 - y1)/2);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

//Finding sheep
procedure FindSheep(var x1, y1, x2, y2: integer);
var
  x, y, z, v, how, value, rownr, lastrowvalue, tvalue, countvalue, testvalue,
  ones, twoes, xxis, yyis: integer;
  IsBigBody, IsHorn: boolean;
begin
  x := x1; y := y1; z := x2; v := y2;
  if ((z - x) >= ((v - y) + 13)) then how := 1 else if (((z - x) + 13) <= (v - y)) then how := 2 else how := 3;
  IsBigBody := False;
  IsHorn := False;
  xxis := z - x;
  yyis := v - y;

  if (how = 1)then
  begin
    rownr := 0;
    lastrowvalue := 1;
    countvalue := 0;
    ones := 0;
    twoes := 0;
    FoundAnimal := False;
    for x := x1 to z do
    begin
      value := 0;
      for y := y1 to v do
      begin
        if (c[x][y] = clred) then inc(value);
        b[x][y] := True;
      end;
      inc(rownr);
      tvalue := 0;
      if (value <= 5) and (value > 0) then tvalue := 1;
      if (value > 5) and (value < 15) then tvalue := 2;
      if (value > 15) and (value < 45) then tvalue := 3;
      if not(tvalue <> 1) or not(tvalue <> 2) or not(tvalue <> 0) or not(tvalue <> 3) then
      begin
        if (lastrowvalue = tvalue) then
        begin
          inc(countvalue);
        end else
        begin
          if (countvalue <> 0) and (lastrowvalue <> 0) then
          begin
            if (countvalue > 2) or (lastrowvalue = 2) then
            begin
//              WriteLn(inttostr(lastrowvalue) + ' [' + inttostr(countvalue) + ']');
              if (lastrowvalue = 1) then inc(ones);
              if (lastrowvalue = 2) and (countvalue > 11)  then IsBigBody := True;
              if (lastrowvalue = 2) and (countvalue > 27) then IsBigBody := False;
              if (lastrowvalue = 2) then inc(twoes);
            end;
            countvalue := 1;
            testvalue := 0;
            lastrowvalue := tvalue;
          end;
        end;
      end;
    end;
    if (((ones < 4) and (ones > 0)) and ((twoes > 0) and(twoes < 3))) and (IsBigBody) and (yyis < 27) then
//    if (((ones = 2) and (twoes = 1)) or ((ones = 0) and (twoes = 1)) or ((ones = 2) and (twoes = 2)) or ((ones = 3) and (twoes = 2)) or ((ones = 1) and (twoes = 2)) or ((ones = 0) and (twoes = 2)) or ((ones = 1) and (twoes = 1))) and (IsBigBody) then
    begin
      px := x1 + Round((x2 - x1)/2);
      py := y1 + Round((y2 - y1)/2);
    end;
  end;

  if (how = 2) then
  begin
    rownr := 0;
    lastrowvalue := 1;
    countvalue := 0;
    ones := 0;
    twoes := 0;
    FoundAnimal := False;
    for y := y1 to v do
    begin
      value := 0;
      for x := x1 to z do
      begin
        if (c[x][y] = clred) then inc(value);
        b[x][y] := True;
      end;
      inc(rownr);
      tvalue := 0;
      if (value <= 5) and (value > 0) then tvalue := 1;
      if (value > 5) and (value < 15) then tvalue := 2;
      if (value > 15) and (value < 45) then tvalue := 3;
      if not(tvalue <> 1) or not(tvalue <> 2) or not(tvalue <> 0) or not(tvalue <> 3) then
      begin
        if (lastrowvalue = tvalue) then
        begin
          inc(countvalue);
        end else
        begin
          if (countvalue <> 0) and (lastrowvalue <> 0) then
          begin
            if (countvalue > 2) or (lastrowvalue = 2) then
           begin
//              WriteLn(inttostr(lastrowvalue) + ' [' + inttostr(countvalue) + ']');
              if (lastrowvalue = 1) then inc(ones);
              if (lastrowvalue = 2) and (countvalue > 11)  then IsBigBody := True;
              if (lastrowvalue = 2) and (countvalue > 27) then IsBigBody := False;
              if (lastrowvalue = 2) then inc(twoes);
            end;
            countvalue := 1;
            testvalue := 0;
            lastrowvalue := tvalue;
          end;
        end;
      end;
    end;
    if (((ones < 4) and (ones > 0)) and ((twoes > 0) and(twoes < 3))) and (IsBigBody) and (xxis < 27)then
//    if (((ones = 2) and (twoes = 1)) or ((ones = 0) and (twoes = 1)) or ((ones = 2) and (twoes = 2)) or ((ones = 3) and (twoes = 2)) or ((ones = 1) and (twoes = 2)) or ((ones = 0) and (twoes = 2)) or ((ones = 1) and (twoes = 1))) and (IsBigBody) then
    begin
      px := x1 + Round((x2 - x1)/2);
      py := y1 + Round((y2 - y1)/2);
    end;
  end;

end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


Procedure AnimalCorners(x, y: integer);
var
  sx, sy: Integer;
  Found: Boolean;
begin
  //animy1
  animy1 := y - 5;

  //animx1
  Found := False;
  for sx := x - 25 to x do
    for sy := y + 35 downto y do
     if (x - 25 > 0) then
      if (y + 35 < w) then
    begin
      if (c[sx][sy] = clred) and not (Found) then
      begin
        animx1 := sx - 5;
        Found := True;
      end;
    end;// else AnimalCoords(x, y);

  //animy2
  Found := False;
  for sy := y + 35 downto y do
    for sx := x + 25 downto animx1 do
     if (x + 25 < h) then
      if (y + 25 < w) then
    begin
      if (c[sx][sy] = clred) and not (Found) then
      begin
        animy2 := sy + 5;
        Found := True;
      end;
    end;// else AnimalCoords(x, y);

  //animx2
  Found := False;
  for sx := x + 25 downto x do
    for sy := animy1 to animy2 do
    if(x + 25 < h) then
    begin
      if (c[sx][sy] = clred) and not (Found) then
      begin
        animx2 := sx + 5;
        Found := True;
      end;
    end;// else AnimalCoords(x, y);

end;



begin
  w := 530; h := 350;
  SetLength(c, w + 1, h + 1);
  SetLength(b, w + 1, h + 1);
  bitsize := 7;
  RetData := ImageClient.ReturnData(ImageClient.Target,1,1,w,h);
  //BitBlt(Bmp.Canvas.Handle, 0, 0, w, h, ClientHDC, 1, 1, SRCCOPY);
  Result := False;


//  for y := 0 to h do c[0][y] := 0;
//  for y := 0 to w do c[x][0] := 0;
//  for y := 0 to h do c[530][y] := 0;
  //finding background and coloring 0
  for y := 20 to h - 10 do
  begin
    Line := RetData.Ptr + y * RetData.RowLen;
    for x := 20 to w - 10 do
    begin
      c[x][y] := RGB(Line[x].R, Line[x].G, Line[x].B);
      if (Line[x].G <> 0) then
      begin
        Lum1 := (Line[x].G * 3);
        Lum2 := (Line[x].R + Line[x].B);
      end else c[x][y] := 0;
      if ((lum2 / lum1) < 1.2) then c[x][y] := 0;
    end;
  end;



  // finding animals and coloring red
  for y := 20 to h - 20 do
    for x := 20 to w - 20 do
    if (c[x][y] <> 0) then
    begin
      c[x][y] := clred;
      b[x][y] := False;
    end;


  FoundAnim := False;
  for y := 20 to h - 10 do
    for x := 20 to w - 10 do
    if (c[x][y] = clred) and not(b[x][y]) and not(FoundAnim)then
    begin
      BgColor := c[x][y];
      FillColor := c[x][y];
      b[x][y] := True;
      Area := 0;
      ScanFill(x, y);
    if (Area > 20) then
    begin
      AnimalCorners(x, y);
      CountBRPixels(animx1, animy1, animx2, animy2);
//      WriteLN(Inttostr(animx1 + Round((animx2 - animx1)/2)) + '   ' + IntToStr(animy1 + Round((animy2 - animy1)/2)));


      if (AnimalName = pete_cat) then FindCat(animx1, animy1, animx2, animy2); //working!!
      if (AnimalName = pete_dog) then FindDog(animx1, animy1, animx2, animy2); //working!!
      if (AnimalName = pete_goat) then
      begin
         if (RPixels > 210) and (RPixels < 1000) then
         begin
           px := (animx1 + round((animx2 - animx1) / 2));
           py := (animy1 + round((animy2 - animy1) / 2));
         end;
      end;
      if (AnimalName = pete_sheep) and (RPixels < 180) then FindSheep(animx1, animy1, animx2, animy2); // working??
    end;
  end;



  ImageClient.FreeReturnData(ImageClient.Target);

end;

{- Scar stuff! -}



function GetFunctionCount(): Integer; stdcall; export;
begin
  Result := 7;
end;

function GetFunctionCallingConv(x : integer) : integer; stdcall;
begin
  result := 0;
  case x of
     0..6 : result := 1;
  end;
end;

function GetFunctionInfo(x: Integer; var ProcAddr: Pointer; var ProcDef: PChar): Integer; stdcall;
begin
  case x of
    0:
      begin
        ProcAddr := @Mordaut_GetSlotNr;
        StrPCopy(ProcDef, 'function Mordaut_GetSlotNr(ScanningTime: Extended; ImageClient : TTarget_Exported): integer;');
      end;
    1:
      begin
        ProcAddr := @Mordaut_GetBigSlotNr;
        StrPCopy(ProcDef, 'procedure Mordaut_GetBigSlotNr(ScanningTime: Extended; QuestionType: Integer; ImageClient : TTarget_Exported; var ThaSlots :Integer);');
      end;
    2:
      begin
        ProcAddr := @Mime_AnalyzeAnimation;
        StrPCopy(ProcDef, 'function Mime_AnalyzeAnimation(ImageClient : TTarget_Exported): Integer;');
      end;
    3:
      begin
        ProcAddr := @Leo_AnalyzeCoffin2;
        StrPCopy(ProcDef, 'function Leo_AnalyzeCoffin2(ImageClient : TTarget_Exported): Integer;');
      end;
    4:
      begin
        ProcAddr := @Leo_AnalyzeGraveStone2;
        StrPCopy(ProcDef, 'function Leo_AnalyzeGraveStone2(ImageClient: TTarget_Exported): Integer;');
      end;
    5:
      begin
        ProcAddr := @Pete_AnalyzeAnimal;
        StrPCopy(ProcDef, 'function Pete_AnalyzeAnimal( var AnimalName: Integer; ImageClient : TTarget_Exported): Boolean;');
      end;
    6:
      begin
        ProcAddr := @Pete_FindAnimal;
        StrPCopy(ProcDef, 'function Pete_FindAnimal(var px, py: Integer; AnimalName: integer; ImageClient : TTarget_Exported): Boolean;');
      end;
  else
    x := -1;
  end;
  Result := x;
end;


exports GetFunctionCount;
exports GetFunctionInfo;
exports GetFunctionCallingConv;

end.
//Solver's End Here :)//
//-Iroki//

