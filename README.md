# GAMES202_HW_TEAFOX

* ***Homeworks-for-GAME202-高质量实时渲染-闫令琪***
* 根目录下文件夹对应着每一次作业。
***
## 环境
* **框架**: 用到了Games202提供的基于JS和WebGL的代码框架.
* **语言**: Javascript, glsl
* **外部依赖库**: Three.js，math.js等（详见每次作业lib文件夹)
* **编辑器**: Visual Studio Code
***

## 推荐运行方法  
1. 在Visual Studio Code中安装Live Server插件  
2. 用Visual Studio Code打开作业中index.html所在文件夹  
3. 在VSCode中Ctrl+Shift+P，输入Live Server: Open With Live Server即可运行渲染器。
***
## 目录
0. **Phong Shading-Get start with the WebGL framework**  
熟悉代码框架的热身作业，使用给定的框架书写Phong的VertexShader和FragmentShader  
    - Phong  
    ![ShadowMap](https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/0.Phong%20Shading-Get%20start%20with%20the%20WebGL%20framework/screenshot/phong.png)  
1. **Soft Shadow-ShadowMap,PCF&PCSS**  
实现课程中的部分阴影生成方法：ShadowMap(硬), PCF和PCSS(软).  
    - ShadowMap  
    ![ShadowMap](https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/1.Soft%20Shadow-Shado%EF%BD%97Map%2CPCF%26PCSS/screenshot/ShadowMap.png)  
    - PCF  
    ![PCF](https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/1.Soft%20Shadow-Shado%EF%BD%97Map%2CPCF%26PCSS/screenshot/PCF.png)  
    - PCSS   
    ![PCSS](https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/1.Soft%20Shadow-Shado%EF%BD%97Map%2CPCF%26PCSS/screenshot/PCSS.png)  

2. **Environment Lighting-PRT**  
实现Precomputed Radience Transform,   
本次作业分为两部分，分别是环境光照预计算(C++)
以及使用预计算的结果进行渲染。  
    - **预计算：**  
主要实现了Light(CubeMap表示)的Sphere Harmonic系数计算（存储在3(RGB)*HCoefficientCount
的Array中），以及每个顶点的Radience Transform对于Sphere Harmonic的投影系数的计算（漫反射BRDF下)，存储在
VertexCount ∗SHCoefficientCount的Array中，最终存储为light.txt和transform.txt供渲染使用，
放置在assets/cubemap中的对应文件夹里，预计算的实现主要在prt/src/prt.cpp中。

    - **渲染：**  
构建了PRTMaterial以及对应的shader完成了PRT的渲染，并利用SH的性质实现了环境光照的旋转。
（本次作用使用3阶球谐拟合，使用了简单的低阶SH快速旋转方法.)
    - **结果：**
    - Cornell Box  
    ![Cornell Box](https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/2.Environment%20Lighting-PRT/homework2/ScreenShot/CornellBox.png) 
    - GraceCathedral  
    ![GraceCathedral](https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/2.Environment%20Lighting-PRT/homework2/ScreenShot/GraceCathedral.png) 

3. **Global Illumination-ScreenSpaceReflection(SSR)**  
实现Screen Space Reflection,   
本次作业主要工作有两部分，分别是屏幕空间下光线的求交和用蒙特卡洛积分实现间接光照的估计。
    - **屏幕空间下光线的求交：**  
    对于屏幕空间下光线求交，起点为间接光照着色点，向间接光照方向按试探步的方法步进（超出一定距离则停止，返回false)，并计算到达的点的深度，将其与相应uv的zBuffer值比较，如果该点的深度大于zBuffer值，则该点为交点。

    - **间接光照着色：**  
    为了实现漫反射材质的间接光照，需要法线方向半球进行采样并用蒙特卡洛方法积分获得间接光照的着色，我实现了查询某一点直接光照的函数(遮挡通过简单shadowMap)，以及查询某一点漫反射BSDF的函数，因此,间接光照可表示为:  
        `Lindir+=BSDF(wi,w0,p0)/pdf*bsdf(wi,wo,p1)*DirectLight(p1) `  
        `Linder=Linder/SAMPLE_NUM  `

    - **结果：**
    - Direct Light   
    ![Direct Light](https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/3.Global%20Illumination-ScreenSpaceReflection(SSR)/screenshot/Ldir.png)   
    - inDirect Light   
    ![inDirect Light](https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/3.Global%20Illumination-ScreenSpaceReflection(SSR)/screenshot/Lindir.png)  
    - Screen Space Reflection   
    ![Screen Space Reflection](https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/3.Global%20Illumination-ScreenSpaceReflection(SSR)/screenshot/SSR.png)  

4. **Physically Based Materials**  
实现Microfacet BRDF,   
本次作业主要工作有两个阶段，第一个阶段是实现基本的Microfacet BRDF的材质。考虑到微表面模型存在一个根本问题：
即忽略了微表面平面间的多次弹射，导致了材质的能量损失，尤其是在材质的粗糙度越高时，能量损失越严重。因此，作业的第二阶段是使用Kulla-Conty方法，通过预计算得出能量损失的补偿项，使得材质的渲染结果能近似保持真实的能量守恒。
    - **Microfacet BRDF：**  
    `fr(i,o)=F(i,h)G(i,o,h)D(h)/4(n·i)(n·o)`  
        - **Fresnel项**：选用Schlick近似  
        `F = R0 + (1 − R0)(1 − cosθ)^5`  
        - **NDF项** : 选用GGX法线分布  
        ```glsl
        float DistributionGGX(vec3 N, vec3 H, float roughness)
        {
           // TODO: To calculate GGX NDF here
            float a = roughness*roughness;
            float a2 = a*a;
            float NdotH = max(dot(N, H), 0.0);
            float NdotH2 = NdotH*NdotH;

            float nom   = a2;
            float denom = (NdotH2 * (a2 - 1.0) + 1.0);
            denom = PI * denom * denom;

            return nom / max(denom, 0.0001);
        }
        ```  
        - **Geometry项** : 选用GGX法线分布匹配的Smith 模型:
        ```glsl
        float GeometrySchlickGGX(float NdotV, float roughness)
        {
            // TODO: To calculate Smith G1 here
            float a = roughness;
            float k = (a * a) / 2.0;

            float nom = NdotV;
            float denom = NdotV * (1.0 - k) + k;

            return nom / denom;
        }
        float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
        {
            // TODO: To calculate Smith G here
            float NoV = max(dot(N, V), 0.0);
            float NoL = max(dot(N, L), 0.0);
            float ggx2 = GeometrySchlickGGX(NoV, roughness);
            float ggx1 = GeometrySchlickGGX(NoL, roughness);

            return ggx1 * ggx2;
        }
        ```  
        
    **结果如下** : 可以看出在粗糙度较高时，模型整体都变暗了，没有体现出光线在微表面中的多次弹射。  
        - PBR without bounce in microfacet   
        ![PBR without bounce in microfacet](https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/4.Physical%20Based%20Materials-Kulla-Conty%20BRDF/homework4/screenshot/PBR_origin.png)    

    - **Kulla-Conty BRDF：**   
         - **预计算E(µ)**  
        为了弥补基础Microfacet模型忽略的能量，需要先计算出在入射光强度恒定为1时，对于每个粗糙度和每个出射方向，使用蒙特卡罗方法求解入射方向的积分，得到该E(µo),则可以认为1-E（µo)应是我们对于该粗糙度和出射方向需补充的能量，此时先不考虑颜色（Fresnel项（R0)=1.0) 。该阶段的结果可以存储在一张以粗糙度和cos(出射方向) 的纹理中.
        
            - **半球均匀采样**
            如果通过cos加权在半球上采样入射光i，得到的结果如下:  
            ![LUT_MC](https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/4.Physical%20Based%20Materials-Kulla-Conty%20BRDF/lut-gen/GGX_E_MC_LUT.png)  
            可以看到在粗糙度较低时，我们计算出的积分值非常小并且有很多噪声。这是因为低粗糙度的微表面材质接近镜面反射材质，即微表面的法线 m(即半程向量 h) 集中分布在几何法线 n 附近，而我们由采样入射光方向 i 计算出的微表面法向量 m 分布并不会集中在几何法线 n 附近，也就是说这与实际低粗糙度的微表面法线分布相差很大，因此积分值的方差就会很大。  
            - **GGX 重要性采样**  
            先根据NDF模型，重要性采样微表面法向m，然后利用反射关系计算入射方向，对于采样m的概率密度  
            `pdf(m)=D(m)(m·n)`  
            通过该pdf，可以计算出NDF对应的采样点。然后是计算采样得到的入射方向的概率，只需要将pdf(m)
            转换为pdf(i)，两者之间乘上一个Jacobian项即可。  
            如果通过cos加权在半球上采样入射光i，得到的结果如下:  
            ![LUT_IS](https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/4.Physical%20Based%20Materials-Kulla-Conty%20BRDF/lut-gen/GGX_E_LUT_IS.png) 
         - **预计算Eavg**  
         预计算的 Eavg 应该只随 roughness
        变化而变化。首先对于之前已经预计算得到的 E(µ) ,对于出射方向进行采样，计算出对应的 E(µ)µ，随后按 roughness，将一行的 E(µ)µ 累加除以texture的行宽
        即可，这样可以认为通过简单的均匀采样完成了Eavg积分的近似计算。
            - 半球均匀采样的Eavg  
            ![LUT_Eavg_MC](https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/4.Physical%20Based%20Materials-Kulla-Conty%20BRDF/lut-gen/GGX_Eavg_LUT_MC.png)   
            - 重要性采样的Eavg  
            ![LUT_Eavg_IS](https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/4.Physical%20Based%20Materials-Kulla-Conty%20BRDF/lut-gen/GGX_Eavg_LUT_IS.png)  
            Eavg 表示我们能够看到的能量，在粗糙度低时微表面能量损失少，我们看到的能量多存储结果偏白；在粗糙度高时能量损失多，我们看到的能量少存储结果偏黑，整体上和我们的认知是一致的。  
         - **实时端计算补充** BRDF  
        根据之前计算好的E(u)和Eavg,可以计算出补充BRDF项fms(µo,µi):  
        `fms(µo,µi)= (1 − E(µo))(1 − E(µi))/(π(1 − Eavg))`  
        同样对于有颜色的材质，因为本来就有能量损失，那么fms需要乘上一个附加的BRDF项fadd:  
        `fadd =Favg*Eavg/(1 − Favg(1 − Eavg))`  
        最后对于 Kulla-Conty 材质，可以得到的 BRDF 项 fr 为：  
        `fr = fmicro + fadd ∗ fms`

         - **最终结果**  
        ![PBR](https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/4.Physical%20Based%20Materials-Kulla-Conty%20BRDF/homework4/screenshot/PBR.png)  
        上方为 Kulla-Conty 方法得到的结果，下方为原始结果，可以发现在粗糙度较低时，能量损失的问题得到了解决。








 

