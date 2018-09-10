import sys

def get_num(line):
	temp = line.split()
	return float(temp[-1])

score = -1
longtail_path = sys.argv[1]
longtail_num = sys.argv[2]
file_name = 'ckpt_'+longtail_num+'.longtail.compare'
file_name = longtail_path + '/' + file_name
output_name = 'ckpt_'+longtail_num+'.score'
with open(file_name, 'r') as f:
	lines = f.readlines()
	for i,line in enumerate(lines):
		if 'f_rank' in line:
			target = lines[i+1:i+5]
			scores = []
			for l in target:
				scores.append(get_num(l))
			# print(scores)
			score = int(sum(scores)/4.0*10000)
			break

with open(output_name, 'w') as f:
	f.write(str(score))

