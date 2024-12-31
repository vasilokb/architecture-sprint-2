# Инструкция по настройке MongoDB с использованием Docker

## Шаг 1: Перейдите в директорию проекта

Пожалуйста, перейдите в директорию, где находится файл compose.yaml. Замените <путь_к_вашей_директории> на фактический путь к вашей директории:

	
	cd <путь_к_вашей_директории>\sharding-repl-cache
	
    
Например, если вы находитесь на диске D:, команда может выглядеть так:

	
	cd D:\Practicum\GitHub\myProjects\architecture-sprint-2\sharding-repl-cache
	

## 2. Запустите Docker Compose
	
	docker compose up -d
	
## 3. Инициализация конфигурационного сервера
	Подключитесь к конфигурационному серверу и выполните инициализацию:
	
	docker exec -it configSrv mongosh --host 173.17.0.10 --port 27017
	
В консоли `mongosh` выполните:
	
        
	rs.initiate(
	  {
		_id : "config_server",
		   configsvr: true,
		members: [
		  { _id : 0, host : "configSrv:27017" }
		]
	  }
	);
	
Завершите сессию:
	
	exit();
	
    
## 4. Инициализация первого шарда
Подключитесь к первому шард-серверу:
	
	docker exec -it shard1 mongosh --host 173.17.0.11 --port 27018
	
Выполните инициализацию репликации:
	
	rs.initiate({
		_id: "shard1",
		members: [
			{ _id: 0, host: "shard1:27018" },
			{ _id: 1, host: "shard1_1:27021" },
			{ _id: 2, host: "shard1_2:27022" },
			{ _id: 3, host: "shard1_3:27023" }
		]
	});
	
Завершите сессию:
	
	exit();
	
## 5. Инициализация второго шарда
Подключитесь ко второму шард-серверу:
	
	docker exec -it shard2 mongosh --host 173.17.0.8 --port 27019
	
Выполните инициализацию репликации:
	
	rs.initiate({
		_id: "shard2",
		members: [
			{ _id: 0, host: "shard2:27019" },
			{ _id: 1, host: "shard2_1:27024" },
			{ _id: 2, host: "shard2_2:27025" },
			{ _id: 3, host: "shard2_3:27026" }
		]
	});
	
Завершите сессию:
	
	exit();
	
## 6. Настройка mongos_router
Подключитесь к `mongos_router`:
	
	docker exec -it mongos_router mongosh --host mongos_router --port 27020
	
Или через IP-адрес:
	
	docker exec -it mongos_router mongosh --host 173.17.0.12 --port 27020
	
Добавьте шард-сервер 1:
	
	sh.addShard("shard1/shard1:27018,shard1_1:27021,shard1_2:27022,shard1_3:27023");
    
Добавьте шард-сервер 2:

	sh.addShard("shard2/shard2:27019,shard2_1:27024,shard2_2:27025,shard2_3:27026");
	
Включите шардинг для базы данных:
	
	sh.enableSharding("somedb");
    
Включите шардинг для коллекции:  

	sh.shardCollection("somedb.helloDoc", {"name": "hashed"});

Подключите БД:

	use somedb;

Добавьте документы в коллекцию:

	for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i});

Проверьте их количество:

	db.helloDoc.countDocuments();

Завершите сессию:

	exit();


## 7. В POSTMAN запросите данные


	GET http://localhost:8080/helloDoc/users
