TYPST              := typst
FINAL_SRC          := report/typst/final_report/final_report.typ
BLUEPRINT_SRC      := report/typst/blueprint/blueprint.typ
FINAL_VI_SRC       := report/typst/final_report_vi/final_report.typ
BLUEPRINT_VI_SRC   := report/typst/blueprint_vi/blueprint.typ
FINAL_OUT          := report/typst/final_report/final_report.pdf
BLUEPRINT_OUT      := report/typst/blueprint/blueprint.pdf
FINAL_VI_OUT       := report/typst/final_report_vi/final_report_vi.pdf
BLUEPRINT_VI_OUT   := report/typst/blueprint_vi/blueprint_vi.pdf

.PHONY: all final blueprint final-vi blueprint-vi watch-final watch-blueprint watch-final-vi watch-blueprint-vi clean help build-docs

## Build tất cả 4 file PDF
all: final blueprint final-vi blueprint-vi

## Build Final Report (EN) → final_report/final_report.pdf
final:
	$(TYPST) compile $(FINAL_SRC) $(FINAL_OUT)
	@echo "Done: $(FINAL_OUT)"

## Build Blueprint (EN) → blueprint/blueprint.pdf
blueprint:
	$(TYPST) compile $(BLUEPRINT_SRC) $(BLUEPRINT_OUT)
	@echo "Done: $(BLUEPRINT_OUT)"

## Build Final Report (VI) → final_report_vi/final_report_vi.pdf
final-vi:
	$(TYPST) compile $(FINAL_VI_SRC) $(FINAL_VI_OUT)
	@echo "Done: $(FINAL_VI_OUT)"

## Build Blueprint (VI) → blueprint_vi/blueprint_vi.pdf
blueprint-vi:
	$(TYPST) compile $(BLUEPRINT_VI_SRC) $(BLUEPRINT_VI_OUT)
	@echo "Done: $(BLUEPRINT_VI_OUT)"

## Build all 4 PDFs
build-docs: all

## Live preview Final Report EN (tự reload khi save)
watch-final:
	$(TYPST) watch $(FINAL_SRC) $(FINAL_OUT)

## Live preview Blueprint EN
watch-blueprint:
	$(TYPST) watch $(BLUEPRINT_SRC) $(BLUEPRINT_OUT)

## Live preview Final Report VI
watch-final-vi:
	$(TYPST) watch $(FINAL_VI_SRC) $(FINAL_VI_OUT)

## Live preview Blueprint VI
watch-blueprint-vi:
	$(TYPST) watch $(BLUEPRINT_VI_SRC) $(BLUEPRINT_VI_OUT)

## Xóa toàn bộ PDF output
clean:
	rm -f $(FINAL_OUT) $(BLUEPRINT_OUT) $(FINAL_VI_OUT) $(BLUEPRINT_VI_OUT)
	@echo "Cleaned."

## Hiển thị help
help:
	@echo ""
	@echo "  make                  Build tất cả 4 PDF"
	@echo "  make final            Build final_report.pdf (EN)"
	@echo "  make blueprint        Build blueprint.pdf (EN)"
	@echo "  make final-vi         Build final_report_vi.pdf (VI)"
	@echo "  make blueprint-vi     Build blueprint_vi.pdf (VI)"
	@echo "  make watch-final      Live preview final report (EN)"
	@echo "  make watch-blueprint  Live preview blueprint (EN)"
	@echo "  make watch-final-vi   Live preview final report (VI)"
	@echo "  make watch-blueprint-vi  Live preview blueprint (VI)"
	@echo "  make clean            Xóa tất cả PDF output"
	@echo ""
