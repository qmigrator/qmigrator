#!/bin/bash
# Required user
airflow users create -r 'Admin' -u 'user' -e 'example@example.com' -f 'user' -l 'user' -p $MY_PASSWORD
airflow roles create NView
airflow roles add-perms NView --action 'can_read' --resource 'My Password' 'My Profile' 'DAG Runs' 'Jobs' 'Audit Logs' 'Task Instances' 'SLA Misses' 'Plugins' 'XComs' 'DAGs' 'Datasets' 'ImportError' 'DAG Warnings' 'DAG Dependencies' 'Task Logs' 'Website' 'Pools' 'Cluster Activity'
airflow roles add-perms NView --action 'can_edit' --resource 'My Password' 'My Profile' 'DAG Runs' 'Task Instances' 'DAGs' 'Pools'
airflow roles add-perms NView --action 'can_delete' --resource 'DAG Runs' 'Task Instances' 'DAGs' 'Pools'
airflow roles add-perms NView --action 'menu_access' --resource 'DAG Runs' 'Browse' 'Jobs' 'Audit Logs' 'Task Instances' 'SLA Misses' 'Pools' 'DAG Dependencies' 'DAGs' 'Datasets' 'Documentation' 'Docs'
airflow users create -r 'NView' -u 'airflow' -e 'airflow@example.com' -f 'airflow' -l 'user' -p $MY_PASSWORD