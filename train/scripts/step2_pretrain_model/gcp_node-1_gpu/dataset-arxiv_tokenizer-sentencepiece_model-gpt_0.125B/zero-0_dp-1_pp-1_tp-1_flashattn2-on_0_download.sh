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
input_tokenizer_file=""
output_model_dir=""
save_interval=1000

# Parses the arguments.
while [[ ${#} -gt 0 ]]; do
    case ${1} in
        # Shifts twice for option that takes an argument.
        --input_tokenizer_file) input_tokenizer_file=${2}; shift ;;
        --output_model_dir) output_model_dir=${2}; shift ;;
        --save_interval) save_interval=${2}; shift ;;
        --json_url) json_url=${2}; shift ;;                        ##### 追加
        --json_dir) json_dir=${2}; shift ;;                        ##### 追加
        *) echo "Unknown parameter passed: ${1}"; exit 1 ;;
    esac
    # Shifts once per loop to move to the next key/value.
    shift
done

# Checks the required arguments.
# if [[ -z ${input_tokenizer_file} ]] || [[ -z ${output_model_dir} ]]; then
# if [[ -z ${input_tokenizer_file} ]]  ]]; then
#     echo "Error: Missing required arguments."
#     echo "Usage: ${0} --input_tokenizer_file <input_tokenizer_file> "
#     exit 1
# fi

# Modifies the arguments.
output_model_dir="${output_model_dir%/}"  # Removes a trailing slash "/" if it exists.


##### JSONのURLからファイル名を抽出
json_file=$(basename ${json_url})               ### 追加

# Prints the arguments.
echo "input_tokenizer_file = ${input_tokenizer_file}"
echo "output_model_dir = ${output_model_dir}"
echo "save_interval = ${save_interval}"
echo "json_url = ${json_url}"                   ### 追加
echo "json_file = ${json_file}"                 ### 追加
echo "json_dir = ${json_dir}"                   ### 追加

# If either arxiv_text_document.bin or arxiv_text_document.idx doesn't exist yet,
# then downloads arxiv.jsonl and preprocesses the data.
data_path="${megatron_deepspeed_dir}/dataset/arxiv_text_document"
# if [ ! -f "${data_path}.bin" ] || [ ! -f "${data_path}.idx" ]; then
    # echo "Either ${data_path}.bin or ${data_path}.idx doesn't exist yet, so download arxiv.jsonl and preprocess the data."
    # wget https://data.together.xyz/redpajama-data-1T/v1.0.0/arxiv/arxiv_024de5df-1b7f-447c-8c3a-51407d8d6732.jsonl \
    #     --directory-prefix ${megatron_deepspeed_dir}/dataset/
    wget ${json_url} \
            --directory-prefix ${json_dir}
        # --directory-prefix ${megatron_deepspeed_dir}/dataset/
    # mv ${megatron_deepspeed_dir}/dataset/arxiv_024de5df-1b7f-447c-8c3a-51407d8d6732.jsonl ${megatron_deepspeed_dir}/dataset/arxiv.jsonl
    # mv ${megatron_deepspeed_dir}/dataset/${json_file} ${megatron_deepspeed_dir}/dataset/arxiv.jsonl
        mv ${json_dir}/${json_file} ${json_dir}/arxiv.jsonl

    # python ${megatron_deepspeed_dir}/tools/preprocess_data.py \
    #     --tokenizer-type SentencePieceTokenizer \
    #     --tokenizer-model ${input_tokenizer_file} \
    #     --input ${megatron_deepspeed_dir}/dataset/arxiv.jsonl \
    #     --output-prefix ${megatron_deepspeed_dir}/dataset/arxiv \
    #     --dataset-impl mmap \
    #     --workers 8 \
    #     --append-eod
# else
#     echo "Both ${data_path}.bin and ${data_path}.idx already exist."
# fi
echo ""
