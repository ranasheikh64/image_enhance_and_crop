import os
import sys
import traceback

print("PYTHON_LOG: Script starting...")
print(f"PYTHON_LOG: Python version: {sys.version}")
print(f"PYTHON_LOG: Current directory: {os.getcwd()}")
print(f"PYTHON_LOG: sys.path: {sys.path}")

try:
    print("PYTHON_LOG: Importing Flask...")
    from flask import Flask, request, jsonify
    print("PYTHON_LOG: Flask imported successfully")
    
    print("PYTHON_LOG: Importing OpenCV...")
    import cv2
    print(f"PYTHON_LOG: OpenCV version: {cv2.__version__}")
    
    print("PYTHON_LOG: Importing NumPy...")
    import numpy as np
    print("PYTHON_LOG: NumPy imported successfully")
except Exception as e:
    print(f"PYTHON_LOG: CRITICAL IMPORT ERROR: {e}")
    traceback.print_exc()
    sys.exit(1)

app = Flask(__name__)

def order_points(pts):
    """Orders points for perspective transform: TL, TR, BR, BL"""
    rect = np.zeros((4, 2), dtype="float32")
    s = pts.sum(axis=1)
    rect[0] = pts[np.argmin(s)]
    rect[2] = pts[np.argmax(s)]
    diff = np.diff(pts, axis=1)
    rect[1] = pts[np.argmin(diff)]
    rect[3] = pts[np.argmax(diff)]
    return rect

def four_point_transform(image, pts):
    """Applies perspective transform to get a top-down view"""
    rect = order_points(pts)
    (tl, tr, br, bl) = rect
    
    widthA = np.sqrt(((br[0] - bl[0]) ** 2) + ((br[1] - bl[1]) ** 2))
    widthB = np.sqrt(((tr[0] - tl[0]) ** 2) + ((tr[1] - tl[1]) ** 2))
    maxWidth = max(int(widthA), int(widthB))
    
    heightA = np.sqrt(((tr[1] - br[1]) ** 2) + ((tr[1] - br[1]) ** 2))
    heightB = np.sqrt(((tl[1] - bl[1]) ** 2) + ((tl[1] - bl[1]) ** 2))
    maxHeight = max(int(heightA), int(heightB))
    
    dst = np.array([
        [0, 0],
        [maxWidth - 1, 0],
        [maxWidth - 1, maxHeight - 1],
        [0, maxHeight - 1]], dtype="float32")
    
    M = cv2.getPerspectiveTransform(rect, dst)
    warped = cv2.warpPerspective(image, M, (maxWidth, maxHeight))
    return warped

def detect_document(img):
    """Detects document edges and returns the 4 corner points if found"""
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    gray = cv2.GaussianBlur(gray, (5, 5), 0)
    
    # Edge detection
    edged = cv2.Canny(gray, 75, 200)
    
    # Find contours
    cnts, _ = cv2.findContours(edged.copy(), cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    cnts = sorted(cnts, key=cv2.contourArea, reverse=True)[:5]
    
    doc_cnt = None
    for c in cnts:
        peri = cv2.arcLength(c, True)
        approx = cv2.approxPolyDP(c, 0.02 * peri, True)
        # If it has 4 points, we found a potential document
        if len(approx) == 4:
            doc_cnt = approx
            break
            
    if doc_cnt is not None:
        return doc_cnt.reshape(4, 2)
    return None

def enhance_faces(img):
    """Detects faces and applies edge-preserving beauty filters (premium smoothing)"""
    cascade_path = "cascades/haarcascade_frontalface_default.xml"
    if not os.path.exists(cascade_path):
        cascade_path = os.path.join(os.getcwd(), "cascades", "haarcascade_frontalface_default.xml")
        
    if not os.path.exists(cascade_path):
        return img

    face_cascade = cv2.CascadeClassifier(cascade_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, 1.1, 5)

    if len(faces) == 0:
        return img

    print(f"PYTHON_LOG: Improving {len(faces)} faces...")
    result = img.copy()
    for (x, y, w, h) in faces:
        pad_w, pad_h = int(w*0.1), int(h*0.1)
        x1, y1 = max(0, x-pad_w), max(0, y-pad_h)
        x2, y2 = min(img.shape[1], x+w+pad_w), min(img.shape[0], y+h+pad_h)
        
        roi = result[y1:y2, x1:x2]
        
        # 1. Edge-Preserving Smoothing (Premium Look)
        # flags=1 (RECURSIVE_FILTER), sigma_s=spatial, sigma_r=range
        smoothed_roi = cv2.edgePreservingFilter(roi, flags=1, sigma_s=50, sigma_r=0.4)
        
        # 2. Eye Sharpening (Subtle but clear)
        gaussian_blur = cv2.GaussianBlur(smoothed_roi, (0, 0), 3)
        roi_enhanced = cv2.addWeighted(smoothed_roi, 1.4, gaussian_blur, -0.4, 0)
        
        result[y1:y2, x1:x2] = roi_enhanced
        
    return result

def enhance_image_logic(input_path, output_path):
    """
    Final HD Enhancement Pipeline:
    - Normalization -> Face/Doc Detection -> Denoising -> CLAHE -> HD Sharpening -> Color
    """
    print(f"PYTHON_LOG: Received /enhance request for {input_path}")
    try:
        img = cv2.imread(input_path)
        if img is None: return False, "Failed to read"

        # Step 1: Exposure/Normalization
        img_yuv = cv2.cvtColor(img, cv2.COLOR_BGR2YUV)
        img_yuv[:,:,0] = cv2.equalizeHist(img_yuv[:,:,0])
        img = cv2.cvtColor(img_yuv, cv2.COLOR_YUV2BGR)

        # Step 2: Smart Processing
        doc_pts = detect_document(img)
        if doc_pts is not None:
            img = four_point_transform(img, doc_pts)
        else:
            img = enhance_faces(img)

        # Step 3: Noise Reduction (Subtle)
        img = cv2.fastNlMeansDenoisingColored(img, None, 5, 5, 7, 21)

        # Step 4: Contrast (CLAHE)
        lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
        l = clahe.apply(l)
        img = cv2.cvtColor(cv2.merge((l, a, b)), cv2.COLOR_LAB2BGR)

        # Step 5: High-Definition Detail
        # detailEnhance adds texture, Unsharp Mask adds edge clarity
        img = cv2.detailEnhance(img, sigma_s=10, sigma_r=0.15)
        laplace = cv2.Laplacian(img, cv2.CV_8U)
        img = cv2.subtract(img, laplace) # Sharpens edges significantly

        # Step 6: Vibrant Saturation
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        hsv[:,:,1] = cv2.multiply(hsv[:,:,1], 1.25)
        img = cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR)

        cv2.imwrite(output_path, img)
        return True, "Success"
    except Exception as e:
        print(f"PYTHON_LOG: ERROR: {e}")
        traceback.print_exc()
        return False, str(e)

@app.route('/enhance', methods=['POST'])
def enhance():
    print("PYTHON_LOG: Received /enhance request")
    data = request.json
    if not data:
        print("PYTHON_LOG: ERROR: No JSON data received")
        return jsonify({"status": "error", "message": "No JSON data received"}), 400
        
    input_path = data.get('input_path')
    output_path = data.get('output_path')
    
    if not input_path or not output_path:
        print("PYTHON_LOG: ERROR: Missing paths in request")
        return jsonify({"status": "error", "message": "Missing paths"}), 400
        
    try:
        success, message = enhance_image_logic(input_path, output_path)
        if success:
            return jsonify({"status": "success", "message": message})
        else:
            return jsonify({"status": "error", "message": message}), 500
    except Exception as e:
        print(f"PYTHON_LOG: UNEXPECTED ERROR: {e}")
        traceback.print_exc()
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/ping', methods=['GET'])
def ping():
    print("PYTHON_LOG: Received /ping request")
    return jsonify({"status": "ok"})

def grabcut_remove_bg(img, rect=None):
    """Semi-automatic background removal using GrabCut with speed optimization"""
    # Optimization: Resize for faster processing
    original_h, original_w = img.shape[:2]
    max_dim = 800
    if max(original_h, original_w) > max_dim:
        scale = max_dim / max(original_h, original_w)
        small_img = cv2.resize(img, (int(original_w * scale), int(original_h * scale)))
        if rect:
            rect = (int(rect[0] * scale), int(rect[1] * scale), int(rect[2] * scale), int(rect[3] * scale))
    else:
        small_img = img
        scale = 1.0

    mask = np.zeros(small_img.shape[:2], np.uint8)
    bgdModel = np.zeros((1, 65), np.float64)
    fgdModel = np.zeros((1, 65), np.float64)

    if rect is None:
        h, w = small_img.shape[:2]
        rect = (5, 5, w - 10, h - 10)

    # 3 iterations is usually enough and much faster than 5
    cv2.grabCut(small_img, mask, rect, bgdModel, fgdModel, 3, cv2.GC_INIT_WITH_RECT)
    
    # Resize mask back to original size
    if scale != 1.0:
        mask = cv2.resize(mask, (original_w, original_h), interpolation=cv2.INTER_NEAREST)
    
    mask2 = np.where((mask == 2) | (mask == 0), 0, 1).astype('uint8')
    res = img * mask2[:, :, np.newaxis]
    
    # White background
    background = np.full(img.shape, 255, dtype=np.uint8)
    res = np.where(mask2[:, :, np.newaxis] == 0, background, res)
    return res

def manual_adjust(img, brightness=0, contrast=0, saturation=0):
    """Manually adjust image properties with clipping for stability"""
    # 1. Brightness & Contrast
    alpha = 1.0 + (contrast / 100.0)
    beta = brightness
    img = cv2.convertScaleAbs(img, alpha=alpha, beta=beta)
    
    # 2. Saturation
    if saturation != 0:
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV).astype(np.float32)
        s_alpha = 1.0 + (saturation / 100.0)
        hsv[:, :, 1] = cv2.multiply(hsv[:, :, 1], s_alpha)
        hsv[:, :, 1] = np.clip(hsv[:, :, 1], 0, 255)
        img = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2BGR)
        
    return img

@app.route('/remove_bg', methods=['POST'])
def remove_bg_route():
    data = request.json
    input_path = data.get('input_path')
    output_path = data.get('output_path')
    # rect format: (x, y, w, h)
    rect = data.get('rect') 

    print(f"PYTHON_LOG: Removing background: {input_path}")
    if not os.path.exists(input_path):
        return jsonify({"status": "error", "message": "File not found"}), 404

    try:
        img = cv2.imread(input_path)
        if rect:
            rect = tuple(rect)
        
        res = grabcut_remove_bg(img, rect)
        cv2.imwrite(output_path, res)
        return jsonify({"status": "success", "output_path": output_path})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/adjust', methods=['POST'])
def adjust_route():
    data = request.json
    input_path = data.get('input_path')
    output_path = data.get('output_path')
    brightness = data.get('brightness', 0)
    contrast = data.get('contrast', 0)
    saturation = data.get('saturation', 0)

    try:
        img = cv2.imread(input_path)
        res = manual_adjust(img, brightness, contrast, saturation)
        cv2.imwrite(output_path, res)
        return jsonify({"status": "success", "output_path": output_path})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    print("PYTHON_LOG: Starting Flask server on 0.0.0.0:8080...")
    app.run(host='0.0.0.0', port=8080)
else:
    print(f"PYTHON_LOG: Script imported as module (__name__={__name__})")
    # Some environments might not call if __name__ == "__main__"
    # But serious_python usually does. 
    # To be safe, we can start it here too if needed, but let's stick to standard for now.
    app.run(host='0.0.0.0', port=8080)
