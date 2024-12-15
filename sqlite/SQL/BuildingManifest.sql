CREATE TABLE "Buildings" (
	"Name"	        TEXT NOT NULL UNIQUE,
    "Texture"       TEXT,
	"Food"	        INTEGER,
	"Production"    INTEGER,
	"Science"	    INTEGER,
	"Gold"	        INTEGER,
    "Food_mult"	    NUMBER,
	"Production_mult"NUMBER,
	"Science_mult"	NUMBER,
	"Gold_mult"	    NUMBER,
    "cost"          INTEGER,
	PRIMARY KEY("Name")
);

INSERT INTO "Buildings" (Name, Texture, Food, Production, Science, Gold, Food_mult, Production_mult, Science_mult, Gold_mult, cost)
VALUES
(
    "Bakery", "Assets/Sprites/Library.png",
    2, 0, 0, 0, 
    0, 0, 0, 0.10,
    10
),
(
    "Forge", "Assets/Sprites/Library.png",
    0, 2, 0, 0, 
    0, 0, 0, 0,
    10
),
(
    "Library", "Assets/Sprites/Library.png",
    0, 0, 1, 0, 
    0, 0, 0.20, 0,
    12
);