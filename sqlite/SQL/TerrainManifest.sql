CREATE TABLE "Terrain" (
	"Name"	        TEXT NOT NULL UNIQUE,
	"Food"	        INTEGER,
	"Production"    INTEGER,
	"Science"	    INTEGER,
	"Gold"	        INTEGER,
	"Gate"	        INTEGER,
	PRIMARY KEY("Name")
);

INSERT INTO "Terrain" (Name, Food, Production, Science, Gold, Gate)
VALUES
("Desert", 0, 1, 0, 1, 1),
("Rainforest", 2, 0, 1, 1, 1),
("Shallows", 1, 0, 1, 0, 0);