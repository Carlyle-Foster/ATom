CREATE TABLE "Terrain" (
	"Name"	        TEXT NOT NULL UNIQUE,
	"Food"	        INTEGER,
	"Production"    INTEGER,
	"Science"	    INTEGER,
	"Gold"	        INTEGER,
	"MovementType"	TEXT,
	"hue"			INTEGER,
	PRIMARY KEY("Name")
);

INSERT INTO "Terrain" (Name, Food, Production, Science, Gold, MovementType, hue)
VALUES
("Desert", 0, 1, 0, 1, "land", 70),
("Rainforest", 2, 0, 1, 1, "land", 120),
("Shallows", 1, 0, 1, 0, "coast", 210);