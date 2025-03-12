CREATE TABLE "Terrain" (
	"Name"	        TEXT NOT NULL UNIQUE,
	"Food"	        INTEGER,
	"Production"    INTEGER,
	"Science"	    INTEGER,
	"Gold"	        INTEGER,
	"MovementType"	TEXT,
	"ID"			INTEGER, 
	"SpawnRate"		INTEGER,
	PRIMARY KEY("Name")
);

INSERT INTO "Terrain" (Name, Food, Production, Science, Gold, MovementType, ID, SpawnRate)
VALUES
("rainforest", 2, 0, 1, 1, "land", 3, 400),
("plains", 1, 1, 0, 0, "land", 2, 2000),
("shallows", 1, 0, 1, 0, "coast", 1, 0),
("desert", 0, 1, 0, 1, "land", 4, 400);