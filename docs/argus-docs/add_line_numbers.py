import os
import shutil

def add_line_numbers(input_dir, output_dir):
    """
    Create a complete copy of input_dir with line numbers added to .md and .txt files
    Original files and folder structure remain completely untouched
    """
    # Remove output directory if it exists to start fresh
    if os.path.exists(output_dir):
        shutil.rmtree(output_dir)
    
    os.makedirs(output_dir, exist_ok=True)
    
    # Walk through all subdirectories
    for root, dirs, files in os.walk(input_dir):
        # Create corresponding output directory structure
        rel_path = os.path.relpath(root, input_dir)
        if rel_path == '.':
            output_root = output_dir
        else:
            output_root = os.path.join(output_dir, rel_path)
        os.makedirs(output_root, exist_ok=True)
        
        for filename in files:
            input_file = os.path.join(root, filename)
            output_file = os.path.join(output_root, filename)
            
            if filename.endswith('.md') or filename.endswith('.txt'):
                # Add line numbers to markdown and text files
                try:
                    with open(input_file, 'r', encoding='utf-8') as f:
                        lines = f.readlines()
                    
                    with open(output_file, 'w', encoding='utf-8') as f:
                        for i, line in enumerate(lines, 1):
                            f.write(f"{i:5d}: {line}")
                    
                    print(f"Line-numbered: {input_file} -> {output_file}")
                    
                except Exception as e:
                    print(f"Error processing {input_file}: {e}")
            else:
                # Copy all other files as-is to preserve complete folder structure
                try:
                    shutil.copy2(input_file, output_file)
                    print(f"Copied: {input_file} -> {output_file}")
                except Exception as e:
                    print(f"Error copying {input_file}: {e}")

if __name__ == "__main__":
    # Update these paths to match your directory structure
    input_directory = "База знаний WFM CC/Документация"
    output_directory = "База знаний WFM CC/Документация_numbered"
    
    print(f"Creating numbered copy of '{input_directory}' in '{output_directory}'...")
    print("Original files will remain completely untouched.")
    print("-" * 60)
    
    add_line_numbers(input_directory, output_directory)
    
    print("-" * 60)
    print("Complete! You now have:")
    print(f"  Original: {input_directory} (unchanged)")
    print(f"  Numbered copy: {output_directory} (with line numbers)")