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

devel:
	git checkout devel

master:
	git checkout master

sync:
	git checkout devel
	git push && git push --tags
	git checkout master
	git push && git push --tags
	git checkout devel

merge:
	git checkout master
	git merge --ff-only devel
	git checkout devel
