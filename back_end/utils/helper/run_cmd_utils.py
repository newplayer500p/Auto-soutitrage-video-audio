import subprocess

def run_check(cmd, capture_output=False, timeout=None):
   
    cp = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=timeout)
    if cp.returncode != 0:
        raise subprocess.CalledProcessError(cp.returncode, cmd, output=cp.stdout, stderr=cp.stderr)
    if not capture_output:
        if cp.stderr:
            print(cp.stderr, end="")
    return cp