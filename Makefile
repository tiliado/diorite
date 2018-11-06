valalint:
	valalint src/glib/*.vala
	valalint src/gtk/*.vala
	valalint src/db/*.vala
	valalint src/tests/*.vala
valalint-fix:
	valalint --fix src/glib/*.vala
	valalint --fix src/gtk/*.vala
	valalint --fix src/db/*.vala
	valalint --fix src/tests/*.vala
