CREATE TABLE "Technology" (
    "Name"	        TEXT NOT NULL UNIQUE,
    "Unlocks"       TEXT,
	"Cost"			INTEGER,
	PRIMARY KEY("Name")
);

INSERT INTO Technology (Name, Unlocks, Cost)
VALUES
("Sailing", "Galley", 5),
("metalworking", "Forge", 7);