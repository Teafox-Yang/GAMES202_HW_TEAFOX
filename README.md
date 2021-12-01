# GAMES202_HW_TEAFOX

* ***Homeworks-for-GAME202-高质量实时渲染-闫令琪***
* 根目录下文件夹对应着每一次作业，目前完成了前三次作业（学习中...) 
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
        Lindir+=BSDF(wi,w0,p0)/pdf*bsdf(wi,wo,p1)*DirectLight(p1)  
        Linder=Linder/SAMPLE_NUM  

    - **结果：**
    - Direct Light 
    ![Direct Light][1]
    [1]:https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/3.Global%20Illumination-ScreenSpaceReflection(SSR)/screenshot/Ldir.png  
    - inDirect Light 
    ![inDirect Light][2]
    [2]:https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/3.Global%20Illumination-ScreenSpaceReflection(SSR)/screenshot/Lindir.png 
    - Screen Space Reflection 
    ![Screen Space Reflection][3]
    [3]:https://github.com/Teafox-Yang/GAMES202_HW_TEAFOX/blob/main/3.Global%20Illumination-ScreenSpaceReflection(SSR)/screenshot/SSR.png 

