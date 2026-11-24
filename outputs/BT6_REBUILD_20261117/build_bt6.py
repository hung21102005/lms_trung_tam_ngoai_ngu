"""Build the two BT6 Word deliverables from the source-traced UC catalogue."""

import json
import re
from pathlib import Path

from docx import Document
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor


ROOT = Path(__file__).resolve().parent
CATALOG = json.loads((ROOT / "usecase_catalog.json").read_text(encoding="utf-8"))
DETAILS = json.loads((ROOT / "case_details.json").read_text(encoding="utf-8"))
ACCOUNT = (ROOT.parent / "BT6_TAI_KHOAN_MAU_20261117" / "MAU_USECASE_XU_LY_TAI_KHOAN.md").read_text(encoding="utf-8")
MEMBERS = [
    "Trần Vĩ Hùng – 2324801030011",
    "Nguyễn Thành Đạt – 2324801030046",
    "Bùi Thanh Văn – 2324801030076",
]
BLUE = "1D4ED8"
INK = "1E293B"
PALE = "EFF6FF"
LINE = "D9D9D9"


def account_details():
    data = {}
    for chunk in re.split(r"(?=^### TK-\d+)", ACCOUNT, flags=re.M)[1:]:
        m = re.match(r"### (TK-\d+) — (.+)", chunk)
        if not m:
            continue
        fields = {}
        for row in chunk.splitlines():
            if row.startswith("| ") and not row.startswith("| Trường") and not row.startswith("|---"):
                parts = [p.strip() for p in row.strip("|").split("|")]
                if len(parts) == 2:
                    fields[parts[0]] = parts[1]
        data[m.group(1)] = fields
    return data


ACCOUNT_DETAILS = account_details()
ALL_CASES = [case for group in CATALOG["groups"] for case in group["cases"]]
assert len(ALL_CASES) == 64
assert len({c["id"] for c in ALL_CASES}) == 64
assert len(ACCOUNT_DETAILS) == 11
assert {c["id"] for c in ALL_CASES if not c["id"].startswith("TK-")} == set(DETAILS)
assert all((ROOT / "figma_png" / f"UC-{g['id']}.png").is_file() for g in CATALOG["groups"])


def shade(cell, color):
    tcpr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), color)
    tcpr.append(shd)


def set_borders(table):
    tblpr = table._tbl.tblPr
    borders = OxmlElement("w:tblBorders")
    for side in ("top", "left", "bottom", "right", "insideH", "insideV"):
        x = OxmlElement(f"w:{side}")
        x.set(qn("w:val"), "single")
        x.set(qn("w:sz"), "4")
        x.set(qn("w:color"), LINE)
        borders.append(x)
    tblpr.append(borders)


def cell_text(cell, value, bold=False):
    cell.text = value
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
    for p in cell.paragraphs:
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.space_before = Pt(2)
        p.paragraph_format.line_spacing = 1.5
        for run in p.runs:
            run.font.name = "Times New Roman"
            run.font.size = Pt(13)
            run.bold = bold


def table(doc, headers, rows, widths):
    t = doc.add_table(rows=1, cols=len(headers))
    t.autofit = False
    for i, w in enumerate(widths):
        t.columns[i].width = Cm(w)
    for i, h in enumerate(headers):
        cell_text(t.rows[0].cells[i], h, True)
        shade(t.rows[0].cells[i], BLUE)
        for run in t.rows[0].cells[i].paragraphs[0].runs:
            run.font.color.rgb = RGBColor(255, 255, 255)
    t.rows[0]._tr.get_or_add_trPr().append(OxmlElement("w:tblHeader"))
    for j, row in enumerate(rows):
        cells = t.add_row().cells
        cells[0]._tc.getparent().get_or_add_trPr().append(OxmlElement("w:cantSplit"))
        for i, value in enumerate(row):
            cell_text(cells[i], str(value), i == 0 and len(headers) == 2)
            if j % 2:
                shade(cells[i], "F8FAFC")
    for i, width in enumerate(widths):
        t.columns[i].width = Cm(width)
        for row in t.rows:
            row.cells[i].width = Cm(width)
    tbl_width = t._tbl.tblPr.first_child_found_in("w:tblW")
    tbl_width.set(qn("w:type"), "dxa")
    tbl_width.set(qn("w:w"), str(Cm(sum(widths)).twips))
    set_borders(t)
    doc.add_paragraph().paragraph_format.space_after = Pt(0)
    return t


def field(paragraph, instruction):
    run = paragraph.add_run()
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = instruction
    separate = OxmlElement("w:fldChar")
    separate.set(qn("w:fldCharType"), "separate")
    text = OxmlElement("w:t")
    text.text = "Cập nhật trường trong Word để hiện mục lục"
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    for node in (begin, instr, separate, text, end):
        run._r.append(node)


def setup(doc, task):
    sec = doc.sections[0]
    sec.page_width = Cm(21)
    sec.page_height = Cm(29.7)
    sec.left_margin = Cm(3)
    sec.right_margin = Cm(2)
    sec.top_margin = Cm(2.5)
    sec.bottom_margin = Cm(2.5)
    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = "Times New Roman"
    normal.font.size = Pt(13)
    normal.font.color.rgb = RGBColor.from_string(INK)
    normal.paragraph_format.line_spacing = 1.5
    normal.paragraph_format.space_after = Pt(6)
    for name, size in (("Title", 21), ("Heading 1", 17), ("Heading 2", 14)):
        st = styles[name]
        st.font.name = "Times New Roman"
        st.font.size = Pt(size)
        st.font.bold = True
        st.font.color.rgb = RGBColor.from_string(INK)
        st.paragraph_format.space_before = Pt(13)
        st.paragraph_format.space_after = Pt(7)
        st.paragraph_format.keep_with_next = True
    header = sec.header.paragraphs[0]
    header.text = f"Nhóm 10  |  EduLMS  |  Bài tập tại lớp số 6  |  {task}"
    header.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    for run in header.runs:
        run.font.name = "Times New Roman"
        run.font.size = Pt(9)
        run.font.color.rgb = RGBColor(90, 100, 115)
    footer = sec.footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
    footer.add_run("Nhóm 10 · Trang ")
    field(footer, "PAGE")
    for run in footer.runs:
        run.font.name = "Times New Roman"
        run.font.size = Pt(9)
    settings = doc.settings.element
    upd = OxmlElement("w:updateFields")
    upd.set(qn("w:val"), "true")
    settings.append(upd)


def cover(doc, task):
    doc.add_paragraph()
    p = doc.add_paragraph("BÀI TẬP TẠI LỚP SỐ 6", "Title")
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p = doc.add_paragraph("PHÂN TÍCH VÀ THIẾT KẾ SẢN PHẨM CỦA DỰ ÁN")
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p = doc.add_paragraph(task.upper(), "Title")
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p = doc.add_paragraph("Xây dựng Hệ thống LMS Trung tâm Ngoại ngữ – EduLMS")
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    doc.add_paragraph()
    doc.add_paragraph("Nhóm thực hiện: Nhóm 10")
    for member in MEMBERS:
        doc.add_paragraph(member, style="Normal")
    doc.add_paragraph("Căn cứ thành viên: dòng TÊN NHÓM trong Nhom10_BT1_HeThongLMSTTNN_1.xlsx. Không có thông tin giảng viên được xác minh trong các nguồn đã kiểm tra.")
    doc.add_paragraph("Ngày rà soát source: 17/11/2026")
    doc.add_page_break()
    doc.add_paragraph("Mục lục", "Title")
    field(doc.add_paragraph(), 'TOC \\o "1-2" \\h \\z \\u')
    doc.add_page_break()


def add_task1():
    doc = Document()
    setup(doc, "Task 1")
    cover(doc, "Task 1 – Biểu đồ Use Case")
    doc.add_heading("1. Phạm vi và phương pháp", 1)
    doc.add_paragraph(
        "Tài liệu trình bày các mục tiêu nghiệp vụ có điểm tương tác Flutter và xử lý NestJS được đối chiếu với source hiện tại. "
        "Mỗi ellipse trong sơ đồ là một mục tiêu của actor; một frame Figma là sơ đồ phân hệ gồm nhiều mục tiêu liên quan. "
        "Phân quyền trên đường liên kết theo controller/guard Backend, không suy ra chỉ từ menu Flutter."
    )
    doc.add_paragraph(
        "Đề Bài tập tại lớp số 6 quy định tên Use Case bắt đầu bằng động từ, vẽ sơ đồ cho chức năng hệ thống và có bảng đặc tả ở Task 2. "
        "Các ví dụ trong đề không được dùng làm chức năng EduLMS. Bằng chứng ở đây là đọc source, chưa phải kết quả kiểm thử E2E."
    )
    doc.add_heading("2. Actor và trạng thái kiểm chứng", 1)
    doc.add_paragraph(
        "Role được xác minh từ controller, guard và schema gồm super_admin, branch_admin, academic_staff, cashier, teacher, teaching_assistant, student, parent. "
        "Khách vãng lai là actor của các endpoint @Public. Các nhãn “người dùng có tài khoản” và “người dùng đã đăng nhập” chỉ nhóm tình huống tham gia, không phải role mới."
    )
    doc.add_paragraph(
        "Có 9 sơ đồ phân hệ với 64 mục tiêu. Chỉ xác nhận mức triển khai tĩnh khi có UI, đường gọi API và Backend xử lý. "
        "Không tự tuyên bố đã chạy thành công với PostgreSQL, Redis, email, VNPay hoặc thiết bị thật."
    )
    for g in CATALOG["groups"]:
        doc.add_paragraph(f"UC-{g['id']} – {g['name']}: {len(g['cases'])} mục tiêu nghiệp vụ.")
    doc.add_heading("3. Sơ đồ Use Case chi tiết", 1)
    for index, g in enumerate(CATALOG["groups"], 1):
        doc.add_heading(f"3.{index}  UC-{g['id']}  {g['name']}", 2)
        actor_p = doc.add_paragraph("Actor: " + ", ".join(g["actors"]) + ".")
        actor_p.paragraph_format.keep_with_next = True
        img = ROOT / "figma_png" / f"UC-{g['id']}.png"
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.keep_with_next = True
        p.add_run().add_picture(str(img), width=Cm(16))
        p = doc.add_paragraph(f"Hình {index}. Sơ đồ UC-{g['id']} – {g['name']}; đối tượng gốc có thể chỉnh sửa trong Figma.")
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        table(
            doc,
            ["Mã", "Mục tiêu của actor", "API và bằng chứng source"],
            [[c["id"], c["name"], c["api"] + "\n" + c["source"]] for c in g["cases"]],
            [1.6, 4.2, 10.2],
        )
    doc.add_heading("4. Đối chiếu và giới hạn", 1)
    doc.add_paragraph(
        "Mã Use Case trong hình, danh mục và Task 2 được đối chiếu 1:1. Chín frame Figma chứa 64 ellipse; Task 2 có 64 bảng đặc tả theo mã ellipse. "
        "Trang tài khoản dùng đúng mẫu đã được người dùng duyệt. Các sơ đồ khác áp dụng cùng màu, kiểu actor, system boundary và cách đặt tên."
    )
    doc.add_paragraph(
        "Một số Backend API chưa có thao tác Flutter tương ứng trong phạm vi rà soát: gán vai trò /users/:id/roles, "
        "duyệt yêu cầu học bù, chấm câu tự luận, quản lý mã ưu đãi, gửi thông báo và hoàn tiền. "
        "Chúng không được biểu diễn như luồng người dùng hoàn chỉnh trong bộ sơ đồ này. "
        "Giao diện quản lý tài khoản cũng hiển thị vài hành động cho Academic Staff mà Backend từ chối; Task 2 nêu rõ sai lệch."
    )
    doc.add_paragraph("Figma: https://www.figma.com/design/KxpN1w1fgxiD6vOHrWergk")
    path = ROOT / "BT6_Task1_BieuDo_UseCase_LMS.docx"
    doc.save(path)
    return path


def add_task2():
    doc = Document()
    setup(doc, "Task 2")
    cover(doc, "Task 2 – Đặc tả Use Case")
    doc.add_heading("1. Phương pháp đặc tả", 1)
    doc.add_paragraph(
        "Mỗi ellipse thuộc 9 sơ đồ Task 1 có một bảng đặc tả với cùng mã. Luồng chính phản ánh điểm tương tác Flutter, request, "
        "xử lý service và kết quả dữ liệu được tìm thấy trong source. Các trường hợp chưa kiểm thử E2E được giữ ở mức xác minh bằng mã nguồn."
    )
    doc.add_heading("2. Danh mục Use Case", 1)
    table(
        doc,
        ["Mã", "Tên Use Case", "Sơ đồ"],
        [[c["id"], c["name"], "UC-" + g["id"]] for g in CATALOG["groups"] for c in g["cases"]],
        [1.7, 10.5, 3.8],
    )
    doc.add_heading("3. Bảng đặc tả", 1)
    for g in CATALOG["groups"]:
        doc.add_heading("3." + str(CATALOG["groups"].index(g) + 1) + "  " + g["name"], 2)
        for case in g["cases"]:
            cid = case["id"]
            doc.add_heading(cid + "  " + case["name"], 2)
            actors = ", ".join(g["actors"][i] for i in case["actors"])
            if cid.startswith("TK-"):
                a = ACCOUNT_DETAILS[cid]
                rows = [
                    ("Use Case ID", cid),
                    ("Use Case Name", case["name"]),
                    ("Description", a.get("Mục tiêu", case["name"])),
                    ("Actor(s)", a.get("Actor", actors)),
                    ("Pre-Condition(s)", a.get("Tiền điều kiện", "")),
                    ("Post-Condition(s)", a.get("Hậu điều kiện", "")),
                    ("Basic Flow", a.get("Luồng chính", "")),
                    ("Alternative Flow", a.get("Luồng thay thế", "")),
                    ("Business Rules", a.get("Quy tắc / bằng chứng", "")),
                    ("Non-Functional Requirement", "JWT/role guard và DTO validation ở các endpoint được nêu; chưa có kết quả đo thời gian đáp ứng hoặc mức sẵn dùng."),
                ]
            else:
                x = DETAILS[cid]
                rows = [
                    ("Use Case ID", cid),
                    ("Use Case Name", case["name"]),
                    ("Description", f"{actors} thực hiện mục tiêu “{case['name']}” trong EduLMS."),
                    ("Actor(s)", actors),
                    ("Pre-Condition(s)", x["pre"]),
                    ("Post-Condition(s)", x["post"]),
                    ("Basic Flow", "1. Actor mở chức năng và nhập/chọn dữ liệu cần thiết.\n2. " + x["flow"] + "\n3. Client hiển thị kết quả trả về; chỉ xác nhận thành công khi API hoàn tất."),
                    ("Alternative Flow", "2a. " + x["alt"]),
                    ("Business Rules", x["rules"]),
                    ("Non-Functional Requirement", "Endpoint được bảo vệ bởi JWT/role và/hoặc DTO validation theo source; chưa có số liệu hiệu năng hay availability được đo."),
                ]
            rows.append(("Bằng chứng triển khai", case["api"] + "\n" + case["source"]))
            table(doc, ["Trường", "Đặc tả"], rows, [3.6, 12.4])
    doc.add_heading("4. Kiểm tra đồng bộ và giới hạn", 1)
    doc.add_paragraph(
        "64 mã trong Task 1, Figma và 64 bảng ở Task 2 trùng nhau. Từng dòng bằng chứng dẫn tới Backend Controller/Service và Flutter. "
        "Trạng thái này là kiểm chứng bằng đọc source, chưa phải chứng nhận chạy E2E. Các API chỉ có Backend/Repository không được coi là Use Case hoàn chỉnh."
    )
    doc.add_paragraph(
        "Các sai lệch cần sửa trong sản phẩm: UI tài khoản còn cho Academic Staff thấy thao tác khóa/cấp lại mật khẩu, "
        "trong khi Backend không cấp quyền; một số chức năng như duyệt học bù, hoàn tiền và gán vai trò mới có API/Bloc nhưng chưa thấy form kích hoạt."
    )
    path = ROOT / "BT6_Task2_DacTa_UseCase_LMS.docx"
    doc.save(path)
    return path


if __name__ == "__main__":
    print(add_task1())
    print(add_task2())
