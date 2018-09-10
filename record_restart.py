import sys
from datetime import datetime
time_stamp = datetime.now()

longtail_path = sys.argv[1]
longtail_num = sys.argv[2]
old_longtail_num = sys.argv[3]
score_new = sys.argv[4]
score_old = sys.argv[5]

file_name = 'restart_record'
file_name = longtail_path + '/' + file_name

string = 'remove ckpt_' + str(longtail_num) + ' and restart ckpt_' + str(old_longtail_num)
string = string + ' at ' + time_stamp.strftime('%Y.%m.%d-%H:%M:%S')
string += '\n'
string = string + 'old score is ' + str(score_old) + ', but the new score is ' + str(score_new)
with open(file_name, 'a') as f:
	f.write(string + '\n')
