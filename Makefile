# Makefile for emr-oozie-sample
#
# driver for emr-oozie.  you'll need to have emr commandline tools installed and configured
# as well as the s3cmd software.  you may need to adjust the variables below then do a 
# "% make create" to create the cluster with the appropriate bootrap actions.  
#
# NOTE:  this is not meant to be used for production, use this as an example that you
# can modify to meet your needs.  no warrantee express or implied.  use at your own risk.
#
#
# run 
# % make
# to get the list of options.
#
# karnab@amazon.com

#
# commands setup (ADJUST THESE IF NEEDED)
# 
S3CMD                   = s3cmd
EMR						= elastic-mapreduce
CLUSTERSIZE				= 2
REGION                  = us-east
KEY						= normal

# 
# make targets 
#

help:
	@echo "help for Makefile for SimpleEMR sample project"
	@echo "make create           - create an EMR Cluster with default settings (2 x c1.medium)"
	@echo "make destroy          - clean up everything (terminate cluster and remove s3 bucket)"
	@echo "make ssh              - log into head node of cluster"


#
# removes all data copied to s3
#
cleanbootstrap:
	-${S3CMD} -r rb s3://$(USER).oozie.emr/

#
# top level target to tear down cluster and cleanup everything
#
destroy: cleanbootstrap
	@ echo deleting server stack oozie.emr
	-${EMR} -j `cat ./jobflowid` --terminate
	rm ./jobflowid

#
# push data into s3 
#
bootstrap: 
	-${S3CMD} mb s3://$(USER).oozie.emr
	${S3CMD} sync --acl-public ./config s3://${USER}.oozie.emr/ 

#
# top level target to create a new cluster of c1.mediums
#
create: bootstrap
	@ if [ -a ./jobflowid ]; then echo "jobflowid exists! exiting"; exit 1; fi
	@ echo creating EMR cluster
	${EMR} elastic-mapreduce --create --alive --name "$(USER)'s sample oozie Cluster" \
	--num-instances ${CLUSTERSIZE} \
	--instance-type c1.medium  \
	--bootstrap-action s3://elasticmapreduce/bootstrap-actions/configure-hadoop \
	--args "-c,hadoop.proxyuser.oozie.hosts=*,-c,hadoop.proxyuser.oozie.groups=*,-h,dfs.permissions=false" \
	--bootstrap-action s3://${USER}.oozie.emr/config/config-oozie.sh | cut -d " " -f 4 > ./jobflowid

#	--bootstrap-action s3://${USER}.oozie.emr/config/config-oozie.sh
#
# logs:  use this to see output of jobs
#

logs: 
	${EMR} -j `cat ./jobflowid` --logs


#
# ssh: quick wrapper to ssh into the master node of the cluster
#
ssh:
	${EMR} -j `cat ./jobflowid` --ssh


