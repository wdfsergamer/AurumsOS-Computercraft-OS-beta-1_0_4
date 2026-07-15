# mini Python demo for AurumOS
print("Sticky Notes")
path = "/x32/Desktop/sticky_notes.txt"
note = input("New sticky note:")
append_file(path, "[note] " + note)
print("Sticky note saved.")
open(path)
