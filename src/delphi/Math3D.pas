unit Math3D;

interface

uses
  Types;

function VectorLength(const V: TVector3D): Single;
procedure VectorSubtract(const A, B: TVector3D; var OutV: TVector3D);
procedure VectorAdd(const A, B: TVector3D; var OutV: TVector3D);
procedure VectorScale(const InV: TVector3D; Scale: Single; var OutV: TVector3D);
function VectorDistance(const A, B: TVector3D): Single;
procedure NormalizeAngles(var Angles: TVector3D);

implementation

{ RVA 0x13728: 3D Magnitude Calculation using x87 FPU }
function VectorLength(const V: TVector3D): Single;
begin
  Result := Sqrt((V.X * V.X) + (V.Y * V.Y) + (V.Z * V.Z));
end;

{ RVA 0x13764: Vector Subtraction }
procedure VectorSubtract(const A, B: TVector3D; var OutV: TVector3D);
begin
  OutV.X := A.X - B.X;
  OutV.Y := A.Y - B.Y;
  OutV.Z := A.Z - B.Z;
end;

procedure VectorAdd(const A, B: TVector3D; var OutV: TVector3D);
begin
  OutV.X := A.X + B.X;
  OutV.Y := A.Y + B.Y;
  OutV.Z := A.Z + B.Z;
end;

{ RVA 0x138E0: Vector Scaling }
procedure VectorScale(const InV: TVector3D; Scale: Single; var OutV: TVector3D);
begin
  OutV.X := InV.X * Scale;
  OutV.Y := InV.Y * Scale;
  OutV.Z := InV.Z * Scale;
end;

function VectorDistance(const A, B: TVector3D): Single;
var
  Diff: TVector3D;
begin
  VectorSubtract(A, B, Diff);
  Result := VectorLength(Diff);
end;

procedure NormalizeAngles(var Angles: TVector3D);
begin
  while Angles.X > 89.0 do Angles.X := Angles.X - 180.0;
  while Angles.X < -89.0 do Angles.X := Angles.X + 180.0;
  while Angles.Y > 180.0 do Angles.Y := Angles.Y - 360.0;
  while Angles.Y < -180.0 do Angles.Y := Angles.Y + 360.0;
  Angles.Z := 0.0;
end;

end.
