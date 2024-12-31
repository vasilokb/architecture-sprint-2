# Инструкция по настройке MongoDB с использованием Docker

## Шаг 1: Перейдите в директорию проекта

Пожалуйста, перейдите в директорию, где находится файл compose.yaml. Замените <путь_к_вашей_директории> на фактический путь к вашей директории:

	```
	cd <путь_к_вашей_директории>\sharding-repl-cache
	```
Например, если вы находитесь на диске D:, команда может выглядеть так:

	``` bash
	cd D:\Practicum\GitHub\myProjects\architecture-sprint-2\sharding-repl-cache
	```

## 2. Запустите Docker Compose
	```bash
	docker compose up -d
	```
## 3. Инициализация конфигурационного сервера
	Подключитесь к конфигурационному серверу и выполните инициализацию:
	```bash
	docker exec -it configSrv mongosh --host 173.17.0.10 --port 27017
	```
В консоли `mongosh` выполните:
	```javascript
	rs.initiate(
	  {
		_id : "config_server",
		   configsvr: true,
		members: [
		  { _id : 0, host : "configSrv:27017" }
		]
	  }
	);
	```
Завершите сессию:
	```javascript
	exit();
	```
## 4. Инициализация первого шарда
Подключитесь к первому шард-серверу:
	```bash
	docker exec -it shard1 mongosh --host 173.17.0.11 --port 27018
	```
Выполните инициализацию репликации:
	```javascript
	rs.initiate({
		_id: "shard1",
		members: [
			{ _id: 0, host: "shard1:27018" },
			{ _id: 1, host: "shard1_1:27021" },
			{ _id: 2, host: "shard1_2:27022" },
			{ _id: 3, host: "shard1_3:27023" }
		]
	});
	```
Завершите сессию:
	```javascript
	exit();
	```
### 5. Инициализация второго шарда
Подключитесь ко второму шард-серверу:
	```bash
	docker exec -it shard2 mongosh --host 173.17.0.8 --port 27019
	```
Выполните инициализацию репликации:
	```javascript
	rs.initiate({
		_id: "shard2",
		members: [
			{ _id: 0, host: "shard2:27019" },
			{ _id: 1, host: "shard2_1:27024" },
			{ _id: 2, host: "shard2_2:27025" },
			{ _id: 3, host: "shard2_3:27026" }
		]
	});
	```
Завершите сессию:
	```javascript
	exit();
	```
## 6. Настройка mongos_router
Подключитесь к `mongos_router`:
	```bash
	docker exec -it mongos_router mongosh --host mongos_router --port 27020
	```
Или через IP-адрес:
	```bash
	docker exec -it mongos_router mongosh --host 173.17.0.12 --port 27020
	```
Добавьте шард-серверы:
	```javascript
	sh.addShard("shard1/shard1:27018,shard1_1:27021,shard1_2:27022,shard1_3:27023");
	sh.addShard("shard2/shard2:27019,shard2_1:27024,shard2_2:27025,shard2_3:27026");
	```
Включите шардинг для базы данных и коллекции:
	```javascript
	sh.enableSharding("somedb");
	sh.shardCollection("somedb.helloDoc", {"name": "hashed"});
	```
Подключите БД:
	```javascript
	use somedb;
	```
Добавьте документы в коллекцию:
	```javascript
	for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i});
	```
Проверьте их количество:
	```javascript
	db.helloDoc.countDocuments();
	```
Завершите сессию:
	```javascript
	exit();
	```

## 7. В POSTMAN запросите данные

	```
	GET http://localhost:8080/helloDoc/users
	```