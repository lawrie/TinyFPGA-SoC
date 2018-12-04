import binascii
filename = 'test.bin'
with open(filename, 'rb') as f:
    content = f.read()
    for x in content:
        print(binascii.hexlify(x))
