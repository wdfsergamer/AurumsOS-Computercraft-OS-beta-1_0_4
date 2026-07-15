class Win7Run {
    public static void main(String[] args) {
        System.out.println("Windows 7 Run");
        System.out.println("Examples: builtin:files, builtin:settings, /x32/Programs/win7_notepad.py");
        String target = input("Open:");
        Aurum.run(target);
    }
}
