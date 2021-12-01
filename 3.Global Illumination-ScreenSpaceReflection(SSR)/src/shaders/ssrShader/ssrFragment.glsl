#ifdef GL_ES
precision highp float;
#endif

uniform vec3 uLightDir;
uniform vec3 uCameraPos;
uniform vec3 uLightRadiance;
uniform sampler2D uGDiffuse;
uniform sampler2D uGDepth;
uniform sampler2D uGNormalWorld;
uniform sampler2D uGShadow;
uniform sampler2D uGPosWorld;

varying mat4 vWorldToScreen;
varying highp vec4 vPosWorld;

#define M_PI 3.1415926535897932384626433832795
#define TWO_PI 6.283185307
#define INV_PI 0.31830988618
#define INV_TWO_PI 0.15915494309
#define SAMPLE_NUM 50

float Rand1(inout float p) {
  p = fract(p * .1031);
  p *= p + 33.33;
  p *= p + p;
  return fract(p);
}

vec2 Rand2(inout float p) {
  return vec2(Rand1(p), Rand1(p));
}

float InitRand(vec2 uv) {
	vec3 p3  = fract(vec3(uv.xyx) * .1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

vec3 SampleHemisphereUniform(inout float s, out float pdf) {
  vec2 uv = Rand2(s);
  float z = uv.x;
  float phi = uv.y * TWO_PI;
  float sinTheta = sqrt(1.0 - z*z);
  vec3 dir = vec3(sinTheta * cos(phi), sinTheta * sin(phi), z);
  pdf = INV_TWO_PI;
  return dir;
}

vec3 SampleHemisphereCos(inout float s, out float pdf) {
  vec2 uv = Rand2(s);
  float z = sqrt(1.0 - uv.x);
  float phi = uv.y * TWO_PI;
  float sinTheta = sqrt(uv.x);
  vec3 dir = vec3(sinTheta * cos(phi), sinTheta * sin(phi), z);
  pdf = z * INV_PI;
  return dir;
}

void LocalBasis(vec3 n, out vec3 b1, out vec3 b2) {
  float sign_ = sign(n.z);
  if (n.z == 0.0) {
    sign_ = 1.0;
  }
  float a = -1.0 / (sign_ + n.z);
  float b = n.x * n.y * a;
  b1 = vec3(1.0 + sign_ * n.x * n.x * a, sign_ * b, -sign_ * n.x);
  b2 = vec3(b, sign_ + n.y * n.y * a, -n.y);
}

vec4 Project(vec4 a) {
  return a / a.w;
}

float GetDepth(vec3 posWorld) {
  float depth = (vWorldToScreen * vec4(posWorld, 1.0)).w;
  return depth;
}

/*
 * Transform point from world space to screen space([0, 1] x [0, 1])
 *
 */
vec2 GetScreenCoordinate(vec3 posWorld) {
  vec2 uv = Project(vWorldToScreen * vec4(posWorld, 1.0)).xy * 0.5 + 0.5;
  return uv;
}

float GetGBufferDepth(vec2 uv) {
  float depth = texture2D(uGDepth, uv).x;
  if (depth < 1e-2) {
    depth = 1000.0;
  }
  return depth;
}

vec3 GetGBufferNormalWorld(vec2 uv) {
  vec3 normal = texture2D(uGNormalWorld, uv).xyz;
  return normal;
}

vec3 GetGBufferPosWorld(vec2 uv) {
  vec3 posWorld = texture2D(uGPosWorld, uv).xyz;
  return posWorld;
}

float GetGBufferuShadow(vec2 uv) {
  float visibility = texture2D(uGShadow, uv).x;
  return visibility;
}

vec3 GetGBufferDiffuse(vec2 uv) {
  vec3 diffuse = texture2D(uGDiffuse, uv).xyz;
  diffuse = pow(diffuse, vec3(2.2));
  return diffuse;
}

/*
 * Evaluate diffuse bsdf value.
 *
 * wi, wo are all in world space.
 * uv is in screen space, [0, 1] x [0, 1].
 *
 */
vec3 EvalDiffuse(vec3 wi, vec2 uv) {
  vec3 L = vec3(0.0);
  vec3 kd = GetGBufferDiffuse(uv)/M_PI;
  vec3 normal = GetGBufferNormalWorld(uv);
  // vec3 h= normalize(normalize(wi) + normalize(wo));
  // float nDotH = 0.5*dot(normal,h)+0.5;
  // L = nDotH*kd;
  L = kd*dot(normalize(normal),normalize(wi));
  return L;
}

/*
 * Evaluate directional light with shadow map
 * uv is in screen space, [0, 1] x [0, 1].
 *
 */
vec3 EvalDirectionalLight(vec2 uv) {
  vec3 Le = vec3(0.0);
  float shadow = GetGBufferuShadow(uv);
  Le = shadow*uLightRadiance;
  return Le;
}

bool RayMarch(vec3 ori, vec3 dir, out vec3 hitPos) {
  float step = 1.0;
  vec3 position = ori+dir*step;
  float zdepth, bufferDepth;
  zdepth = GetDepth(position);
  bufferDepth = GetGBufferDepth(GetScreenCoordinate(position));
  for(int i=0;i<6;i++)
  {
    if(zdepth>bufferDepth)
    {
      hitPos = position;
      return true;
    }
    position += dir*step;
    zdepth = GetDepth(position);
    bufferDepth = GetGBufferDepth(GetScreenCoordinate(position));
  }
  return false;
}


void main() {
  float s = InitRand(gl_FragCoord.xy);

  vec3 Lindir = vec3(0.0);
  vec2 uv = GetScreenCoordinate(vPosWorld.xyz);
  for(int i = 0 ; i < SAMPLE_NUM ; i++)
  {
    float pdf;
    vec3 localDir = SampleHemisphereUniform(s,pdf);
    vec3 normal = GetGBufferNormalWorld(uv);
    vec3 b1,b2;
    LocalBasis(normal,b1,b2);

    mat4 rot=mat4(
    b1.x,b1.y,b1.z,0,
    b2.x,b2.y,b2.z,0,
    normal.x,normal.y,normal.z,0,
    0,0,0,1
    );
    vec3 dir = (rot*vec4(localDir,1.0)).xyz;
    vec3 intersect;
    if(RayMarch(vPosWorld.xyz,dir,intersect))
    {
      vec2 uv1 = GetScreenCoordinate(intersect);
      vec3 n = GetGBufferNormalWorld(uv1);
      vec3 l = EvalDiffuse(intersect-vPosWorld.xyz,uv)/pdf*EvalDiffuse(n,uv1)*EvalDirectionalLight(uv1);
      Lindir+=l;
    }
  }
  Lindir=Lindir/float(SAMPLE_NUM);

  // Do speclar to validate the RayMarch function
  // vec3 nDir=normalize(GetGBufferNormalWorld(uv));
  // vec3 vDir= normalize(uCameraPos-vPosWorld.xyz);
  // vec3 rDir= reflect(vDir,nDir);
  // vec3 intersect;
  // if(RayMarch(vPosWorld.xyz,rDir,intersect))
  // {
  //   vec2 uv1 = GetScreenCoordinate(intersect);
  //   vec3 n = GetGBufferNormalWorld(uv1);
  //   Lindir = EvalDiffuse(n,uv1);
  // }

  vec3 Le = EvalDirectionalLight(uv);
  vec3 diff = EvalDiffuse(uLightDir,uv);
  vec3 Ldir = Le*diff;
  vec3 L=Lindir;
  vec3 color = pow(clamp(L, vec3(0.0), vec3(1.0)), vec3(1.0 / 2.2));
  gl_FragColor = vec4(color, 1.0);
}
