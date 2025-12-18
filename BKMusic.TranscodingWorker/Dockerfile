# 请参阅 https://aka.ms/customizecontainer 以了解如何自定义调试容器，以及 Visual Studio 如何使用此 Dockerfile 生成映像以更快地进行调试。

# 此阶段用于在快速模式(默认为调试配置)下从 VS 运行时
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER $APP_UID
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

USER root
RUN cat <<EOF > /etc/apt/sources.list
deb https://mirrors.ustc.edu.cn/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-security main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
EOF

USER root
RUN \
    # 切换到国内镜像源
    #sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    #sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/ubuntu.sources && \
    # 更新并安装
    apt-get update && \
    apt-get install -y ffmpeg && \

    # 清理
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER app

# 此阶段用于生成服务项目
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["BKMusic.TranscodingWorker/BKMusic.TranscodingWorker.csproj", "BKMusic.TranscodingWorker/"]
RUN dotnet restore "./BKMusic.TranscodingWorker/BKMusic.TranscodingWorker.csproj"
COPY . .
WORKDIR "/src/BKMusic.TranscodingWorker"
RUN dotnet build "./BKMusic.TranscodingWorker.csproj" -c $BUILD_CONFIGURATION -o /app/build

# 此阶段用于发布要复制到最终阶段的服务项目
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./BKMusic.TranscodingWorker.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

#sudo sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list


# 此阶段在生产中使用，或在常规模式下从 VS 运行时使用(在不使用调试配置时为默认值)
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "BKMusic.TranscodingWorker.dll"]

# docker exec -it 91b1af6a458802b9c9b096777f338ae0ef8c965fb3f92b2fd7098594e1284f4e /bin/bash