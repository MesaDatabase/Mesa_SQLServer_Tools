1. Node needs to be added to the Cluster. Unfortunately, removing or adding SQL nodes to SQL cluster requires the MSCS running and the node added to the cluster as a possible Owner. Otherwise, we can´t remove/add nodes into SQL Server cluster.
2. DBA To remove Node from SQL Cluster. It shouldn´t need a downtime, but from experience, it can cause one. (Downtime probably required)
3. DBA to remove Local SQL Installation on Node (Client Tools, Admin Tools, Connectivity Tools, Non clustered components)
4. DBA Add back Node to the cluster. When adding cluster nodes it is done at RTM (Retail) level, it would require later patching.
5. DBA Install Client, admin and connectivity tools and Non clustered components on Node.
6. Patch Database Engine and Non Clustered components on recently added node (Requires Downtime)
7. Failover/Failback testing
