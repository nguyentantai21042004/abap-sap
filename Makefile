TYPST         := typst
FINAL_SRC     := report/typst/final_report/final_report.typ
BLUEPRINT_SRC := report/typst/blueprint/blueprint.typ
FINAL_OUT     := report/typst/final_report/final_report.pdf
BLUEPRINT_OUT := report/typst/blueprint/blueprint.pdf

.PHONY: all final blueprint watch-final watch-blueprint clean help build-docs

## Build cả hai file PDF
all: final blueprint

## Build Final Report → final_report/final_report.pdf
final:
	$(TYPST) compile $(FINAL_SRC) $(FINAL_OUT)
	@echo "Done: $(FINAL_OUT)"

## Build Blueprint → blueprint/blueprint.pdf
blueprint:
	$(TYPST) compile $(BLUEPRINT_SRC) $(BLUEPRINT_OUT)
	@echo "Done: $(BLUEPRINT_OUT)"

## Build both PDFs
build-docs: final blueprint

## Live preview Final Report (tự reload khi save)
watch-final:
	$(TYPST) watch $(FINAL_SRC) $(FINAL_OUT)

## Live preview Blueprint
watch-blueprint:
	$(TYPST) watch $(BLUEPRINT_SRC) $(BLUEPRINT_OUT)

## Xóa toàn bộ PDF output
clean:
	rm -f $(FINAL_OUT) $(BLUEPRINT_OUT)
	@echo "Cleaned."

## Hiển thị help
help:
	@echo ""
	@echo "  make              Build cả hai PDF"
	@echo "  make final        Build final_report.pdf"
	@echo "  make blueprint    Build blueprint.pdf"
	@echo "  make watch-final        Live preview final report"
	@echo "  make watch-blueprint    Live preview blueprint"
	@echo "  make clean        Xóa PDF output"
	@echo ""
