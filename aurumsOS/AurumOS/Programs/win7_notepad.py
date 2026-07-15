# mini Python demo for AurumOS
print("Windows 7 Notepad")
path = "/x32/Desktop/notepad.txt"
text = input("Type a note:")
append_file(path, text)
print("Saved to " + path)
open(path)
