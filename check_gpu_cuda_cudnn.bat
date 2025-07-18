@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo        GPU、CUDA 和 cuDNN 检测工具
echo ========================================
echo.

:: 检测NVIDIA显卡型号
echo [正在检测NVIDIA显卡...]
nvidia-smi >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未检测到NVIDIA显卡或驱动未正确安装。
    goto check_cuda
)

for /f "tokens=3,4" %%a in ('nvidia-smi --query-gpu=name --format=csv,noheader') do (
    set "gpu_name=%%a %%b"
)
echo [成功] 检测到显卡: !gpu_name!

:: 检测CUDA版本
:check_cuda
echo.
echo [正在检测CUDA版本...]
nvcc --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [警告] 未检测到CUDA或CUDA未添加到系统路径。
) else (
    for /f "tokens=5,6" %%a in ('nvcc --version ^| findstr "release"') do (
        set "cuda_version=%%b"
    )
    echo [成功] 检测到CUDA版本: !cuda_version!
)

:: 检测cuDNN
echo.
echo [正在检测cuDNN...]
set "cudnn_found=false"
set "cudnn_path="

:: 检查可能的cuDNN路径
for %%p in ("%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA" "%ProgramW6432%\NVIDIA GPU Computing Toolkit\CUDA" "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA") do (
    if exist "%%~p" (
        for /d %%d in ("%%~p\*") do (
            if exist "%%~d\bin\cudnn*.dll" (
                set "cudnn_found=true"
                set "cudnn_path=%%~d\bin"
            )
        )
    )
)

if "!cudnn_found!"=="true" (
    echo [成功] 找到cuDNN文件路径: !cudnn_path!
    
    :: 检查特定的cuDNN文件
    if exist "!cudnn_path!\cudnn_ops_infer64_8.dll" (
        echo [成功] 找到关键文件: cudnn_ops_infer64_8.dll
    ) else (
        echo [警告] 未找到关键文件: cudnn_ops_infer64_8.dll，可能会导致运行机器学习模型时出错。
    )
) else (
    echo [警告] 未找到cuDNN或cuDNN未正确安装。
)

:: 总结
echo.
echo ========================================
echo                检测结果
echo ========================================
if %errorlevel% neq 0 (
    echo [警告] NVIDIA显卡驱动可能未正确安装。
) else (
    echo [√] NVIDIA显卡: !gpu_name!
)

if defined cuda_version (
    echo [√] CUDA版本: !cuda_version!
) else (
    echo [×] CUDA未安装或未添加到系统路径。
)

if "!cudnn_found!"=="true" (
    echo [√] cuDNN已安装
    if not exist "!cudnn_path!\cudnn_ops_infer64_8.dll" (
        echo [!] 警告: 缺少关键文件cudnn_ops_infer64_8.dll
    )
) else (
    echo [×] cuDNN未安装或未正确配置。
)

echo.
echo ========================================
echo                建议操作
echo ========================================
echo.

if not defined cuda_version (
    echo - 请安装CUDA工具包，建议从NVIDIA官方网站下载。
)

if "!cudnn_found!"=="false" (
    echo - 请安装cuDNN库，需要从NVIDIA开发者网站下载。
)

if "!cudnn_found!"=="true" if not exist "!cudnn_path!\cudnn_ops_infer64_8.dll" (
    echo - 您的cuDNN安装可能不完整，请重新安装或更新cuDNN。
)

echo.
echo 按任意键退出...
pause >nul
