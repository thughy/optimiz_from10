import sys

longtail_path = sys.argv[1]
longtail_num = sys.argv[2]
file_name = 'checkpoint'
file_name = longtail_path + '/' + file_name

string = '''model_checkpoint_path: "'''
string = string + longtail_path + '/' + 'ckpt_' + str(longtail_num) + '''"'''
with open(file_name, 'w') as f:
	f.write(string)

