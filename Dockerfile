# syntax = docker/dockerfile:1.3

# begin with JRE 21 to run the server
FROM eclipse-temurin:21-jre

ENV FORGE_INSTALLER=$FORGE_INSTALLER_JAR MOTD=$MOTD

# create and work in server folder within container
VOLUME /forge_server_data
WORKDIR /forge_server_data

# download Log4j patch
RUN curl -fsSL -o Log4jPatcher.jar https://github.com/CreeperHost/Log4jPatcher/releases/download/v1.0.1/Log4jPatcher-1.0.1.jar

# copy forge installer from local storage into container workspace
COPY --chmod=750 $FORGE_INSTALLER_JAR forge-installer.jar

# run forge server installer with Log4j patch applied
RUN java -javaagent:Log4jPatcher.jar -jar forge-installer.jar --installServer

# make the minecraft server jar executable
RUN chmod +x $MINECRAFT_SERVER_JAR

# create EULA agreement file (with agreement set true of course)
RUN echo -e "#By changing the setting below to TRUE you are indicating your agreement to our EULA (https://account.mojang.com/documents/minecraft_eula).\n#Tue Mar 26 23:31:53 MDT 2024\neula=true" > eula.txt

# enable whitelist
RUN sed -i "s/white-list=false/white-list=true/g" > server.properties

# set MOTD
CMD sed -i "s/A Minecraft Server/$MOTD/g" > server.properties

# not sure
STOPSIGNAL SIGTERM

# expose minecraft dedicated port for port forwarding
EXPOSE 25565

# run server as containers main process
ENTRYPOINT java -javaagent:Log4jPatcher.jar -Xmx4G -Xms4G -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=16M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=50 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar minecraft_server.1.12.2.jar --nogui

# checkup on container?
#HEALTHCHECK --start-period=1m --interval=5s --retries=24 CMD mc-health