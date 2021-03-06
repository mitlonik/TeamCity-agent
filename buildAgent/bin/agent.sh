#!/bin/sh
# ------------------------------------------------------------------------------------------------
# Please do not modify this script, your changes will be lost after each TeamCity server upgrade !
# ------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------
# TeamCity build agent start/stop script
# ---------------------------------------------------------------------
# Environment variables:
#
# JAVA_HOME or JRE_HOME     Set Java to use by agent process. Must point to a directory with bin/java executable.
#
# TEAMCITY_AGENT_MEM_OPTS   Set agent memory options (JVM options)
#
# TEAMCITY_AGENT_OPTS       Set additional agent JVM options
#
# TEAMCITY_LAUNCHER_OPTS    Set agent launcher JVM options
#
# TEAMCITY_AGENT_PREPARE_SCRIPT    name of a script to execute before start/stop
#
# ---------------------------------------------------------------------

old_cwd=`pwd`
this_script="$0"
command_name=$1
command_sub_name=$2
workingdir=`dirname "$this_script"`
cd "$workingdir"


if [ "$CONFIG_FILE" = "" ]; then
    CONFIG_FILE=../conf/buildAgent.properties
fi
if [ "$LOG_DIR" = "" ]; then
    LOG_DIR=../logs
fi

TEAMCITY_AGENT_MEM_OPTS_ACTUAL="$TEAMCITY_AGENT_MEM_OPTS"

if [ "$TEAMCITY_AGENT_MEM_OPTS_ACTUAL" = "" ]; then
    TEAMCITY_AGENT_MEM_OPTS_ACTUAL="-Xmx384m"
fi

# uncomment for debugging OOM errors:
#    TEAMCITY_AGENT_MEM_OPTS_ACTUAL="$TEAMCITY_AGENT_MEM_OPTS_ACTUAL -XX:+HeapDumpOnOutOfMemoryError"

TEAMCITY_LAUNCHER_OPTS_ACTUAL="-ea $TEAMCITY_LAUNCHER_OPTS"
TEAMCITY_AGENT_OPTS_ACTUAL="$TEAMCITY_AGENT_OPTS -ea $TEAMCITY_AGENT_MEM_OPTS_ACTUAL -Dteamcity_logs=$LOG_DIR/"

if [ -f ../conf/teamcity-agent-log4j.xml ]; then
    TEAMCITY_AGENT_OPTS_ACTUAL="$TEAMCITY_AGENT_OPTS_ACTUAL -Dlog4j.configuration=file:../conf/teamcity-agent-log4j.xml"
fi

if [ "$PID_FILE" = "" ]; then
    PID_FILE=$LOG_DIR/buildAgent.pid
fi

TEAMCITY_LAUNCHER_CLASSPATH="../launcher/lib/launcher.jar"

check_alive() {
    ps_alive=0
    if [ -f "$PID_FILE" ] ; then
       if ps -p `cat $PID_FILE` >/dev/null 2>&1; then 
          ps_alive=1;  
       else
          rm $PID_FILE
       fi
    fi

    if [ "$ps_alive" = "0" ]; then
        return 1
    else
        return 0
    fi
}

exit1() {
  cd "$old_cwd"
  exit $1
}

case "$command_name" in
start|run)
        if check_alive ; then
          echo "Build agent is already running with PID `cat $PID_FILE`"
          exit1 1
        fi

        if [ ! -r "$CONFIG_FILE" ]; then
          mkdir ../conf >/dev/null 2>&1
          mv *.properties *.xml *.dtd ../conf >/dev/null 2>&1
        fi

        echo "Starting TeamCity build agent..."

        . ./findJava.sh
        find_java "`pwd`/../jre" "`pwd`/../../jre";
        if [ $? -ne 0 ]; then
          echo "Java not found. Cannot start TeamCity agent. Please ensure JDK or JRE is installed and JAVA_HOME environment variable points to it."
          exit1 1
        fi 

        LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.
        export LD_LIBRARY_PATH

        mkdir -p $LOG_DIR 2>/dev/null

        if [ -f ../lib/latest/launcher.jar ]; then
            rm ../lib/launcher.jar
            mv ../lib/latest/launcher.jar ../lib/launcher.jar
            TEAMCITY_LAUNCHER_CLASSPATH="../lib/launcher.jar"            
        fi

        if [ "$TEAMCITY_AGENT_PREPARE_SCRIPT" != "" ]; then
            "$TEAMCITY_AGENT_PREPARE_SCRIPT" $*
        fi

        "$JRE_HOME/bin/java" $TEAMCITY_LAUNCHER_OPTS_ACTUAL -cp $TEAMCITY_LAUNCHER_CLASSPATH jetbrains.buildServer.agent.Check $TEAMCITY_AGENT_OPTS_ACTUAL jetbrains.buildServer.agent.AgentMain -file $CONFIG_FILE
        check_result="$?"
        if [ "$check_result" != "0" ]; then
           exit1 1;
        fi

        if [ "$command_name" = "start" ]; then
          nohup "$JRE_HOME/bin/java" $TEAMCITY_LAUNCHER_OPTS_ACTUAL -cp $TEAMCITY_LAUNCHER_CLASSPATH jetbrains.buildServer.agent.Launcher $TEAMCITY_AGENT_OPTS_ACTUAL jetbrains.buildServer.agent.AgentMain -file $CONFIG_FILE > "$LOG_DIR/output.log" 2> "$LOG_DIR/error.log" &
          launcher_pid=$!
          echo $launcher_pid > $PID_FILE

          echo "Done [$launcher_pid], see log at `cd $LOG_DIR && pwd`/teamcity-agent.log"

        else
          "$JRE_HOME/bin/java" $TEAMCITY_LAUNCHER_OPTS_ACTUAL -cp $TEAMCITY_LAUNCHER_CLASSPATH jetbrains.buildServer.agent.Launcher $TEAMCITY_AGENT_OPTS_ACTUAL jetbrains.buildServer.agent.AgentMain -file $CONFIG_FILE
        fi
        ;;
stop)
   echo "Stopping TeamCity build agent..."

   if [ "$command_sub_name" = "kill" ] ; then
         if check_alive ; then
            echo "Stopping buildAgent [`cat $PID_FILE`]"
            kill `cat $PID_FILE`
            for i in 1 2 3 4 5 6 7 8 9 10; do
              if [ !check_alive ]; then break; fi
              sleep 1
            done
            if [ !check_alive ]; then
              echo "Stopped"
              rm $PID_FILE
            else
              echo "Cannot stop buildAgent"
              exit1 1
            fi

         else
            echo "$PID_FILE not found, nothing to stop."
         fi

   else
        check_alive ;
         
        . ./findJava.sh
        find_java "`pwd`/../jre" "`pwd`/../../jre";
        if [ $? -ne 0 ]; then
          echo "Java not found. Cannot stop TeamCity agent. Please ensure JDK or JRE is installed and JAVA_HOME environment variable points to it."
          exit1 1
        fi
         
        LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.
        export LD_LIBRARY_PATH
  
        if [ "$command_sub_name" = "force" ]; then
            FORCE="force"
        fi

        if [ -f ../lib/latest/launcher.jar ]; then
            TEAMCITY_LAUNCHER_CLASSPATH="../lib/latest/launcher.jar"
        fi

        if [ "$TEAMCITY_AGENT_PREPARE_SCRIPT" != "" ]; then
            "$TEAMCITY_AGENT_PREPARE_SCRIPT" $*
        fi

        "$JRE_HOME/bin/java" $TEAMCITY_LAUNCHER_OPTS_ACTUAL -cp $TEAMCITY_LAUNCHER_CLASSPATH jetbrains.buildServer.agent.Stop -file $CONFIG_FILE $FORCE $TEAMCITY_AGENT_OPTS_ACTUAL

        check_result="$?"
        if [ "$check_result" != "0" ]; then
          echo "Cannot stop agent gracefully, you can try to kill agent by '$this_script stop kill' command"
          exit1 1
        fi

   fi
   ;;
*)
        echo "JetBrains TeamCity Build Agent"
        echo "Usage: "
        echo "  $this_script start     - to start build agent in background"
        echo "  $this_script stop      - to stop build agent after current build finish"
        echo " "
        echo "  $this_script run         - to start build agent in the current console"
        echo "  $this_script stop force  - to stop build agent terminating currently running build"
        exit1 1
        ;;
esac

exit1 0
