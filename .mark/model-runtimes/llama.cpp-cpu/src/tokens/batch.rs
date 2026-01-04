//! src/tokenizer/batch.rs — Input batch builder for llama.cpp

use crate::errors::{LlamaError, Result};
use crate::tokens::tokenize;
use crate::bindings::*;
use std::os::raw::c_int;
use std::ptr;

pub struct TokenBatch {
    pub batch: llama_batch,
    _tokens: Vec<llama_token>,
    _positions: Vec<llama_pos>,
    _seq_ids: Vec<*mut llama_seq_id>,
    _seq_val: Vec<llama_seq_id>,
    _n_seq: Vec<c_int>,
}

/// Build a llama_batch whose token positions start at `start_pos`,
/// ensuring Y = X+1 ordering for llama.cpp’s KV cache.
pub fn build_batch(tokens: &[llama_token], start_pos: llama_pos) -> TokenBatch {
    let n = tokens.len();

    // Copy tokens into owned Vec
    let mut tokens_vec = tokens.to_vec();

    // Positions must pick up where the last batch left off
    let mut positions: Vec<llama_pos> =
        (start_pos..start_pos + n as llama_pos).collect();

    // All tokens belong to sequence 0
    let mut seq_val = vec![0 as llama_seq_id; n];
    let mut seq_ids: Vec<*mut llama_seq_id> =
        seq_val.iter_mut().map(|v| v as *mut _).collect();

    // One sequence per token
    let mut n_seq = vec![1 as c_int; n];

    let batch = llama_batch {
        n_tokens: n as c_int,
        token: tokens_vec.as_mut_ptr(),
        embd: ptr::null_mut(),
        pos: positions.as_mut_ptr(),
        n_seq_id: n_seq.as_mut_ptr(),
        seq_id: seq_ids.as_mut_ptr(),
        logits: ptr::null_mut(),
    };

    TokenBatch {
        batch,
        _tokens: tokens_vec,
        _positions: positions,
        _seq_ids: seq_ids,
        _seq_val: seq_val,
        _n_seq: n_seq,
    }
}

/// Processes a batch of input strings and returns tokenized outputs.
pub fn process_batch(inputs: Vec<String>) -> Result<Vec<Vec<String>>> {
    if inputs.is_empty() {
        return Err(LlamaError::TokenizationError(
            "Input batch is empty".to_string(),
        ));
    }

    let mut results = Vec::with_capacity(inputs.len());

    for input in inputs {
        match tokenize::tokenize(&input) {
            Ok(tokens) => results.push(tokens),
            Err(e) => return Err(LlamaError::TokenizationError(format!(
                "Failed to tokenize input '{}': {}",
                input, e
            ))),
        }
    }

    Ok(results)
}

/// Processes a batch of detokenization
pub fn detokenize_batch(token_batches: Vec<Vec<String>>) -> Result<Vec<String>> {
    if token_batches.is_empty() {
        return Err(LlamaError::TokenizationError(
            "Token batch vector is empty".to_string(),
        ));
    }

    let mut outputs = Vec::with_capacity(token_batches.len());

    for tokens in token_batches {
        match tokenize::detokenize(&tokens) {
            Ok(s) => outputs.push(s),
            Err(e) => return Err(LlamaError::TokenizationError(format!(
                "Failed to detokenize batch: {}",
                e
            ))),
        }
    }

    Ok(outputs)
}
