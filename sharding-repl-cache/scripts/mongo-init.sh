#!/bin/bash
set -x

# Инициализируем БД
echo "Initiate the config server"
docker exec -i configSrv mongosh --host 173.17.0.10 --port 27017 <<EOF
rs.initiate({
  _id: "config_server",
  configsvr: true,
  members: [
    { _id: 0, host: "configSrv:27017" }
  ]
});
exit;
EOF
if [ $? -ne 0 ]; then
  echo "Ошибка инициализации config server"
fi

echo "Initiate shard1"
docker exec -i shard1 mongosh --host 173.17.0.11 --port 27018 <<EOF
rs.initiate({
  _id: "shard1",
  members: [
    { _id: 0, host: "shard1:27018" },
    { _id: 1, host: "shard1_1:27021" },
    { _id: 2, host: "shard1_2:27022" },
    { _id: 3, host: "shard1_3:27023" }
  ]
});
exit;
EOF
if [ $? -ne 0 ]; then
  echo "Ошибка инициализации shard1"
fi

echo "Initiate shard2"
docker exec -i shard2 mongosh --host 173.17.0.8 --port 27019 <<EOF
rs.initiate({
  _id: "shard2",
  members: [
    { _id: 0, host: "shard2:27019" },
    { _id: 1, host: "shard2_1:27024" },
    { _id: 2, host: "shard2_2:27025" },
    { _id: 3, host: "shard2_3:27026" }
  ]
});
exit;
EOF
if [ $? -ne 0 ]; then
  echo "Ошибка инициализации shard2"
fi

# Инициализация маршрутизатора
echo "Initiate the mongos router"
docker exec -i mongos_router mongosh --host 173.17.0.12 --port 27020 <<EOF
sh.addShard("shard1/shard1:27018,shard1_1:27021,shard1_2:27022,shard1_3:27023");
sh.addShard("shard2/shard2:27019,shard2_1:27024,shard2_2:27025,shard2_3:27026");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc",{"name":"hashed"});
use somedb;
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i});
db.helloDoc.countDocuments();
EOF
if [ $? -ne 0 ]; then
  echo "Ошибка при инициализации маршрутизатора mongos"
fi
