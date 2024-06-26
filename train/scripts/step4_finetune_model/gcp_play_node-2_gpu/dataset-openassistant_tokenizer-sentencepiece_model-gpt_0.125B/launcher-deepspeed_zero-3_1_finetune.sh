#!/bin/bash

set -e
echo ""

# Stores the directory paths as variables.
ucllm_nedo_dev_train_dir="${HOME}/ucllm_nedo_dev/train"
megatron_deepspeed_dir="${ucllm_nedo_dev_train_dir}/Megatron-DeepSpeed"
echo "ucllm_nedo_dev_train_dir = ${ucllm_nedo_dev_train_dir}"
echo "megatron_deepspeed_dir = ${megatron_deepspeed_dir}"
echo ""

# Initializes the arguments.
input_model_name_or_path=""
output_tokenizer_and_model_dir=""

echo "########### 1"


# Parses the arguments.
while [[ ${#} -gt 0 ]]; do
    case ${1} in
        # Shifts twice for option that takes an argument.
        --input_model_name_or_path) input_model_name_or_path=${2}; shift ;;
        --output_tokenizer_and_model_dir) output_tokenizer_and_model_dir=${2}; shift ;;
        --json_path) json_path=${2}; shift ;;    ### 追加
        --config_yaml) config_yaml=${2}; shift ;;    ### 追加
        # --json_dir) json_dir=${2}; shift ;;    ### 追加
        *) echo "Unknown parameter passed: ${1}"; exit 1 ;;
    esac
    # Shifts once per loop to move to the next key/value.
    shift
done

echo "########### 2"


# Checks the required arguments.
if  [[ -z ${input_model_name_or_path} ]] || [[ -z ${output_tokenizer_and_model_dir} ]] || [[ -z ${json_path} ]] || [[ -z ${json_path} ]] || [[ -z ${config_yaml} ]]; then
    echo "Error: Missing required arguments."
    echo "Usage: ${0} --input_model_name_or_path <input_model_name_or_path> --output_tokenizer_and_model_dir <output_tokenizer_and_model_dir> --json_path <学習データファイルのパス> --config_yaml <config_yamlファイル>"
    exit 1
fi

echo "########### 3"

##### JSONのURLからファイル名を抽出
# json_file=$(basename ${json_url})               ### 追加
# echo ${json_file}

# Prints the arguments.
echo "#######################################"
echo "input_model_name_or_path = ${input_model_name_or_path}"
echo "output_tokenizer_and_model_dir = ${output_tokenizer_and_model_dir}"
# echo "json_url = ${json_url}"                   ### 追加
# echo "json_file = ${json_file}"                 ### 追加
echo "json_path = ${json_path}"                   ### 追加
echo "config_yaml = ${config_yaml}"                   ### 追加
echo "#######################################"
echo ""

# mkdir -p ${output_tokenizer_and_model_dir}

# If openassistant_best_replies_train.jsonl doesn't exist yet,
# then downloads openassistant_best_replies_train.jsonl.
# dataset_file=${ucllm_nedo_dev_train_dir}/llm-jp-sft/dataset/openassistant_best_replies_train.jsonl
dataset_file=${json_path}

# if [ ! -f ${dataset_file} ]; then
#     echo "${dataset_file} doesn't exist yet, so download arxiv.jsonl and preprocess the data."
    # wget https://huggingface.co/datasets/timdettmers/openassistant-guanaco/resolve/main/openassistant_best_replies_train.jsonl \
    #     --directory-prefix ${ucllm_nedo_dev_train_dir}/llm-jp-sft/dataset/
    # wget ${json_url} \
    #     --directory-prefix ${json_dir}
# else
#     echo "${dataset_file} already exists."
# fi
# echo ""

# exit



# Logging.
log_path="${output_tokenizer_and_model_dir}/log"
mkdir -p ${log_path}
host="${HOSTNAME}"
current_time=$(date "+%Y.%m.%d_%H.%M.%S")


echo ${dataset_file}
echo ${input_model_name_or_path}
echo ${output_tokenizer_and_model_dir}
echo ${log_path}/${host}_${current_time}.log




# Creates a hostfile.
script_dir=$(dirname "$0")
hostfile="${script_dir}/hostfile_jobid-${SLURM_JOB_ID}"
nodes=$(scontrol show hostnames $SLURM_JOB_NODELIST)

for node in $nodes
do
  gpu_count=$(ssh ${node} "nvidia-smi --query-gpu=name --format=csv,noheader | wc -l")

  echo "${node} slots=${gpu_count}"
done > "${hostfile}"

echo "hostfile = ${hostfile}"
cat ${hostfile}
echo ""





##### yaml ファイルの読み込み
lr=$(yq -r '.lr' ${config_yaml})
############

echo "#############################"
echo "lr = ${lr}"
echo "#############################"


# exit

# Finetunes the pretrained model.
deepspeed --hostfile ${hostfile} \
    ${ucllm_nedo_dev_train_dir}/llm-jp-sft/train.py \
    --num_train_epochs 2 \
    --per_device_train_batch_size 1 \
    --gradient_accumulation_steps 32 \
    --learning_rate ${lr} \
    --warmup_ratio 0.1 \
    --lr_scheduler_type cosine \
    --bf16 \
    --max_seq_length 2048 \
    --gradient_checkpointing \
    --logging_steps 1 \
    --data_files ${dataset_file} \
    --model_name_or_path ${input_model_name_or_path} \
    --output_dir ${output_tokenizer_and_model_dir} \
    --instruction_template "### Human:" \
    --response_template "### Assistant:" \
    --deepspeed ${script_dir}/deepspeed_config/ds_config_zero3.json \
    2>&1 | tee ${log_path}/${host}_${current_time}.log

echo ""
echo "Finished to finetune the pretrained model."
echo ""


# Finetunes the pretrained model.
# python ${ucllm_nedo_dev_train_dir}/llm-jp-sft/train.py \
#     --num_train_epochs 1 \
#     --per_device_train_batch_size 1 \
#     --learning_rate ${lr} \
#     --warmup_ratio 0.1 \
#     --lr_scheduler_type cosine \
#     --bf16 \
#     --data_files ${dataset_file} \
#     --model_name_or_path ${input_model_name_or_path} \
#     --output_dir ${output_tokenizer_and_model_dir} \
#     --instruction_template "### Human:" \
#     --response_template "### Assistant:" \
#     2>&1 | tee ${log_path}/${host}_${current_time}.log

# echo ""
# echo "Finished to finetune the pretrained model."
# echo ""
