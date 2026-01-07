use anyhow::Result;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

pub struct CrateBuilder {
    workspace_root: PathBuf,
}

impl CrateBuilder {
    pub fn new(workspace_root: PathBuf) -> Self {
        Self { workspace_root }
    }

    /// Create a new crate in the workspace
    pub async fn create_crate(
        &self,
        name: &str,
        crate_type: CrateType,
        dependencies: Vec<String>,
    ) -> Result<PathBuf> {
        let crate_path = self.workspace_root.join("crates").join(name);

        // Create directory structure
        fs::create_dir_all(&crate_path)?;
        fs::create_dir_all(crate_path.join("src"))?;

        // Generate Cargo.toml
        self.generate_cargo_toml(&crate_path, name, &crate_type, &dependencies)?;

        // Generate source files
        match crate_type {
            CrateType::Lib => {
                self.generate_lib_rs(&crate_path)?;
            }
            CrateType::Bin => {
                self.generate_main_rs(&crate_path)?;
            }
        }

        // Update workspace Cargo.toml
        self.add_to_workspace(name)?;

        Ok(crate_path)
    }

    fn generate_cargo_toml(
        &self,
        crate_path: &Path,
        name: &str,
        crate_type: &CrateType,
        dependencies: &[String],
    ) -> Result<()> {
        let mut content = format!(
            r#"[package]
name = "{}"
version.workspace = true
edition.workspace = true

"#,
            name
        );

        // Add binary configuration if needed
        if matches!(crate_type, CrateType::Bin) {
            content.push_str(&format!(
                r#"[[bin]]
name = "{}"
path = "src/main.rs"

"#,
                name
            ));
        }

        // Add dependencies
        content.push_str("[dependencies]\n");
        for dep in dependencies {
            if dep.starts_with("shared-types") || dep.starts_with("model-router") {
                content.push_str(&format!(r#"{} = {{ path = "../{}" }}"#, dep, dep));
                content.push('\n');
            } else {
                content.push_str(&format!("{}.workspace = true\n", dep));
            }
        }

        fs::write(crate_path.join("Cargo.toml"), content)?;
        Ok(())
    }

    fn generate_lib_rs(&self, crate_path: &Path) -> Result<()> {
        let content = r#"// Auto-generated library crate

pub fn hello() -> String {
    "Hello from generated crate!".to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        assert_eq!(hello(), "Hello from generated crate!");
    }
}
"#;
        fs::write(crate_path.join("src/lib.rs"), content)?;
        Ok(())
    }

    fn generate_main_rs(&self, crate_path: &Path) -> Result<()> {
        let content = r#"// Auto-generated binary crate

fn main() {
    println!("Hello from generated binary!");
}
"#;
        fs::write(crate_path.join("src/main.rs"), content)?;
        Ok(())
    }

    fn add_to_workspace(&self, crate_name: &str) -> Result<()> {
        let workspace_toml = self.workspace_root.join("Cargo.toml");
        let content = fs::read_to_string(&workspace_toml)?;

        // Check if already in workspace
        if content.contains(&format!("crates/{}", crate_name)) {
            return Ok(());
        }

        // Find the members array and add new crate
        let new_member = format!("    \"crates/{}\",", crate_name);
        
        // Simple insertion - in production you'd want proper TOML parsing
        let updated = content.replace(
            "members = [",
            &format!("members = [\n{}", new_member),
        );

        fs::write(&workspace_toml, updated)?;
        Ok(())
    }

    /// Compile a specific crate
    pub async fn compile_crate(&self, name: &str) -> Result<String> {
        let output = Command::new("cargo")
            .args(&["build", "-p", name, "--release"])
            .current_dir(&self.workspace_root)
            .output()?;

        if output.status.success() {
            Ok(String::from_utf8_lossy(&output.stdout).to_string())
        } else {
            Err(anyhow::anyhow!(
                "Compilation failed: {}",
                String::from_utf8_lossy(&output.stderr)
            ))
        }
    }

    /// Run tests for a crate
    pub async fn test_crate(&self, name: &str) -> Result<String> {
        let output = Command::new("cargo")
            .args(&["test", "-p", name])
            .current_dir(&self.workspace_root)
            .output()?;

        if output.status.success() {
            Ok(String::from_utf8_lossy(&output.stdout).to_string())
        } else {
            Err(anyhow::anyhow!(
                "Tests failed: {}",
                String::from_utf8_lossy(&output.stderr)
            ))
        }
    }

    /// Generate code within a crate based on specification
    pub async fn generate_code(
        &self,
        crate_name: &str,
        spec: CodeGenerationSpec,
    ) -> Result<()> {
        let crate_path = self.workspace_root.join("crates").join(crate_name);

        match spec {
            CodeGenerationSpec::Function { name, code } => {
                self.add_function_to_crate(&crate_path, &name, &code)?;
            }
            CodeGenerationSpec::Struct { name, fields } => {
                self.add_struct_to_crate(&crate_path, &name, &fields)?;
            }
            CodeGenerationSpec::Module { name, content } => {
                self.add_module_to_crate(&crate_path, &name, &content)?;
            }
        }

        Ok(())
    }

    fn add_function_to_crate(&self, crate_path: &Path, name: &str, code: &str) -> Result<()> {
        let lib_path = crate_path.join("src/lib.rs");
        let mut content = fs::read_to_string(&lib_path)?;

        content.push_str("\n\n");
        content.push_str(&format!("pub fn {}() {{\n", name));
        content.push_str(code);
        content.push_str("\n}\n");

        fs::write(lib_path, content)?;
        Ok(())
    }

    fn add_struct_to_crate(&self, crate_path: &Path, name: &str, fields: &str) -> Result<()> {
        let lib_path = crate_path.join("src/lib.rs");
        let mut content = fs::read_to_string(&lib_path)?;

        content.push_str("\n\n");
        content.push_str(&format!("pub struct {} {{\n", name));
        content.push_str(fields);
        content.push_str("\n}\n");

        fs::write(lib_path, content)?;
        Ok(())
    }

    fn add_module_to_crate(&self, crate_path: &Path, name: &str, module_content: &str) -> Result<()> {
        let module_path = crate_path.join("src").join(format!("{}.rs", name));
        fs::write(module_path, module_content)?;

        // Add module declaration to lib.rs
        let lib_path = crate_path.join("src/lib.rs");
        let mut content = fs::read_to_string(&lib_path)?;
        content.push_str(&format!("\npub mod {};\n", name));
        fs::write(lib_path, content)?;

        Ok(())
    }
}

#[derive(Debug, Clone)]
pub enum CrateType {
    Lib,
    Bin,
}

#[derive(Debug, Clone)]
pub enum CodeGenerationSpec {
    Function { name: String, code: String },
    Struct { name: String, fields: String },
    Module { name: String, content: String },
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;

    #[tokio::test]
    async fn test_create_crate() {
        let temp_dir = env::temp_dir().join("test_workspace");
        let builder = CrateBuilder::new(temp_dir.clone());

        let result = builder
            .create_crate(
                "test-crate",
                CrateType::Lib,
                vec!["tokio".to_string()],
            )
            .await;

        assert!(result.is_ok());
        let crate_path = result.unwrap();
        assert!(crate_path.exists());
        assert!(crate_path.join("Cargo.toml").exists());
        assert!(crate_path.join("src/lib.rs").exists());

        // Cleanup
        let _ = fs::remove_dir_all(temp_dir);
    }
}
