# optimiz_from10
continue optimizing results from 10 ckpt

to start optimizimation, please run optimiz_from10.sh.

merge_longtail_gpu0.sh  will calculated the long tail results

cal_longtaiScore.py     will judge which ckpt is the best

record_restart.py       will record some details when the bad ckpts are removed

rewrite_checkpoint.py   will rewrite the checkpoint file to make the main programm restarts at the new best ckpt
