#!/bin/bash

results_dir="/search/odin/lhs/tensor_exp/transformer/results"
ckpt_num=1
old_ckpt_num=347
start_ckpt_num=347
very_first_ckpt_num=347
jump=10
max_ckpt_num=`expr $start_ckpt_num + $jump`
old_best_ckpt_num=$very_first_ckpt_num
new_best_ckpt_num=$very_first_ckpt_num
loop=0
max_loop=100

score_old=5260
score_new=-1

wait_for_ckpt()
{
  prefix=$1
  num=$2
  suffix=$3
  dir=$4
  name="${prefix}"$num"${suffix}"
  full_name="${dir}""/""${name}"

  while [ 1 ];  do
    if [ -f "$full_name" ]; then
      echo "$name exists!"
      return 1
    else
      echo "waiting for $name"
      sleep 10
    fi
  done
}

wait_for_longtail()
{
  prefix=$1
  num=$2
  suffix=$3
  dir=$4
  name="${prefix}"$num"${suffix}"
  full_name="${dir}""/""${name}"
  if [ -f "$full_name" ]; then
    echo "$name exists!"
  
    python_file_name="cal_longtaiScore.py"
    python $python_file_name $dir $num
    sleep 1.0
    score_file_name="ckpt_"$num".score"
    for line in `cat $score_file_name`
    do
      score_new=$((line))
    done
  else
    echo "$name does not exist!"
    sh_name="merge_longtail_gpu7.sh" 
    nohup sh $sh_name $dir ckpt $num > /dev/null 2>&1 &
    echo "$name started to be processed"
  fi

  if [ ! $score_new -eq -1 ]; then
    echo $score_new
    rm -f $score_file_name
    return 1
  fi

  while [ 1 ];  do
    if [ -f "$full_name" ]; then
      echo "$name exists!"
      python_file_name="cal_longtaiScore.py"
      python $python_file_name $dir $num
      sleep 1.0

      score_file_name="ckpt_"$num".score"
      for line in `cat $score_file_name`
      do
        score_new=$((line))
      done
      
      if [ ! $score_new -eq -1 ]; then
        echo $score_new
        rm -f $score_file_name
        return 1
      fi

    else
      echo "waiting for $name"
      sleep 10.0
    fi
  done
}

kill_and_restart()
{
  killall -9 python
  echo "the training process has been shut down!"
  dir=$1
  ckpt_num=$2

  python_file_name="rewrite_checkpoint.py"
  python $python_file_name $dir $old_ckpt_num
  echo "checkpoint file has been rewrite!"

  ckpt_name="ckpt_"$num
  full_name="${dir}""/""${ckpt_name}"
  rm -f $full_name

  longtail_name="ckpt_"$num".longtail.compare"
  full_name="${dir}""/""${longtail_name}"
  rm -f $full_name
  sh exe8.sh

  python_file_name="record_restart.py"
  python $python_file_name $dir $ckpt_num $score_new $score_old
  echo "restart information has been recorded!"
}


delete_nouse()
{
  dir=$1
  num=$2

  ckpt_name="ckpt_"$num
  full_name="${dir}""/""${ckpt_name}"
  rm -f $full_name
  echo "$full_name has been removed!"
  
  test_ckpt_name="test_ckpt_"$num
  full_name="${dir}""/""${test_ckpt_name}"
  rm -rf $full_name
  echo "$full_name has been removed!"

  python_file_name="cal_longtaiScore.py"
  python $python_file_name $dir $num
  sleep 1.0

  score_file_name="ckpt_"$num".score"
  for line in `cat $score_file_name`
  do
    score_temp=$((line))
  done
  rm -f $score_file_name

  python_file_name="record_restart.py"
  python $python_file_name $dir $num $new_best_ckpt_num $score_temp $score_old
  echo "restart information has been recorded!"


  longtail_name="ckpt_"$num".longtail.compare"
  full_name="${dir}""/""${longtail_name}"
  rm -f $full_name
  echo "$full_name has been removed!"
}


while [ $loop -lt $max_loop ];
do
  for((ckpt_num=$start_ckpt_num;ckpt_num<$max_ckpt_num;ckpt_num++));  
  # while [ $ckpt_num -lt $max_ckpt_num ];
  do
    wait_for_ckpt "ckpt_" $ckpt_num "" $results_dir
    wait_for_longtail "ckpt_" $ckpt_num ".longtail.compare" $results_dir
    
    echo "old_ckpt_num is $old_ckpt_num"
    echo "start_ckpt_num is $start_ckpt_num"
    
    old_ckpt_name="ckpt_"$old_ckpt_num
    new_ckpt_name="ckpt_"$ckpt_num
  
    if [ $score_new -gt $score_old ]; then
      score_old=$score_new
      
      new_best_ckpt_num=$ckpt_num
      echo "score from $new_ckpt_name is greater that from $old_ckpt_name"
      old_ckpt_num=$ckpt_num
    else
      echo "score from $new_ckpt_name is smaller that from $old_ckpt_name"
    fi
    score_new=-1
  done
  
  killall -9 python
  echo "the training process has been shut down!"


  old_best_ckpt_num=$new_best_ckpt_num

  python_file_name="rewrite_checkpoint.py"
  python $python_file_name $results_dir $new_best_ckpt_num
  echo "checkpoint file has been rewrite!"
  

  for((ckpt_num=$start_ckpt_num;ckpt_num<$max_ckpt_num;ckpt_num++));
  do
    if [ ! $ckpt_num -eq $new_best_ckpt_num ]; then
      delete_nouse $results_dir $ckpt_num
    else
      ckpt_name1="ckpt_"$ckpt_num
      cp "${results_dir}""/""${ckpt_name1}" "${results_dir}""/""${ckpt_name1}""_1"
      longtail_name1="ckpt_"$ckpt_num".longtail.compare"
      cp "${results_dir}""/""${longtail_name1}" "${results_dir}""/""${longtail_name1}""_1"
    fi
  done
  
  if [ ! $new_best_ckpt_num -eq $very_first_ckpt_num ]; then
    start_ckpt_num=$new_best_ckpt_num
  fi

  max_ckpt_num=`expr $start_ckpt_num + $jump`

  loop=`expr $loop + 1`

  sh exe8.sh
done

