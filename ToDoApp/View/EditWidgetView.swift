//
//  EditWidgetView.swift
//  ToDoApp
//
//  Created by Bhumi Thummar on 16/05/25.
//

import SwiftUI
import PhotosUI
import TOCropViewController
import WidgetKit
struct EditWidgetView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selection: WidgetBackgroundType = .gradient
    @State private var gradientMode: GradientMode = .selectOne
    @State private var selectedGradient: Int = 0
    @State private var selectedPhotos: [UIImage] = []
    @State private var photoItems: [PhotosPickerItem] = []
    let gradients: [LinearGradient] = WidgetSettingsManager.shared.gradients
    @State private var selectSpecificGradient = true
    @State private var imageToCrop: UIImage?
    @State private var showCropper = false
    var body: some View {
            Form {
                Picker("Background Type", selection: $selection) {
                    Text("None").tag(WidgetBackgroundType.none)
                    Text("Gradient").tag(WidgetBackgroundType.gradient)
                    Text("Photo").tag(WidgetBackgroundType.photo)
                }
                .pickerStyle(SegmentedPickerStyle())

                if selection == .gradient {
                    Section(header: Text("Gradient Background")) {
                        Toggle(isOn: $selectSpecificGradient) {
                            Text("Select specific gradient")
                        }
                        .toggleStyle(SwitchToggleStyle())

                        if selectSpecificGradient {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(0..<gradients.count, id: \.self) { idx in
                                        ZStack{
                                            Color.black
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(12)
                                            gradients[idx]
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(selectedGradient == idx ? Color.accentColor : .clear, lineWidth: 3)
                                                )
                                                .onTapGesture {
                                                    selectedGradient = idx
                                                }
                                        }
                                    }
                                }
                                .padding(.vertical)
                            }
                        } else {
                            Text("Randomly for weekly")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                                .padding(.vertical)
                        }
                    }
                } else  if selection == .photo {
                    // Photo selection section (as in previous answer)
                    Section(header: Text("Max 7 photos allowed").font(.subheadline).foregroundColor(.secondary)) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // Plus button (only show if less than 7 photos)
                                if selectedPhotos.count < 7 {
                                    PhotosPicker(
                                        selection: $photoItems,
                                        maxSelectionCount: 1,
                                        matching: .images
                                    ) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                                .foregroundColor(.accentColor)
                                                .frame(width: 80, height: 80)
                                            Image(systemName: "plus")
                                                .font(.system(size: 30, weight: .bold))
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                    .onChange(of: photoItems) { _,newItems in
                                        guard let item = newItems.last else { return }
                                        item.loadTransferable(type: Data.self) { result in
                                            if case .success(let data?) = result, let uiImage = UIImage(data: data) {
                                                imageToCrop = uiImage
                                                showCropper = true
                                            }
                                            photoItems = []
                                        }
                                    }
                                    .fullScreenCover(isPresented: $showCropper) {
                                        if let imageToCrop = imageToCrop {
                                            CropView(image: imageToCrop) { croppedImage in
                                                if selectedPhotos.count < 7 {
                                                    selectedPhotos.append(croppedImage)
                                                }
                                            }
                                        }
                                    }
                                }
                                ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { idx, image in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipped()
                                            .cornerRadius(12)
                                        Button(action: {
                                            selectedPhotos.remove(at: idx)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Color.white.opacity(0.7))
                                                .clipShape(Circle())
                                        }
                                        .offset(x: 6, y: -6)
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("Edit Widget")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if selection == .photo && selectedPhotos.isEmpty {
                            AlertGlobal.showOkAlert(message: "Please select at least one photo.")
                        }
                        else{
                            let targetSize = CGSize(width: 500, height: 250)
                            let compressedPhotos = selectedPhotos.map { $0.resized(to: targetSize).jpegData(compressionQuality: 0.5) }
                            let settings = WidgetSettings(
                                backgroundType: selection,
                                gradientMode: selectSpecificGradient ? .selectOne : .randomWeekly,
                                selectedGradientIndex: selectSpecificGradient ? selectedGradient : nil,
                                selectedPhotoData: selection == .photo ? compressedPhotos.compactMap { $0 } : nil
                            )
                            WidgetSettingsManager.shared.save(settings)
                            WidgetCenter.shared.reloadAllTimelines()
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                let settings = WidgetSettingsManager.shared.load()
                selection = settings.backgroundType
                selectSpecificGradient = settings.gradientMode == .selectOne
                selectedGradient = settings.selectedGradientIndex ?? 0
                if let photoData = settings.selectedPhotoData {
                    selectedPhotos = photoData.compactMap { UIImage(data: $0) }
                }
            }
    }
}

#Preview {
    EditWidgetView()
}


struct CropView: UIViewControllerRepresentable {
    var image: UIImage
    var onCropped: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> TOCropViewController {
        let cropVC = TOCropViewController(croppingStyle: .default, image: image)
        cropVC.delegate = context.coordinator
        cropVC.resetAspectRatioEnabled = false
        cropVC.aspectRatioPickerButtonHidden = false
        cropVC.aspectRatioPreset = .presetCustom
        cropVC.customAspectRatio = CGSize(width: 2, height: 1)
        cropVC.aspectRatioLockEnabled = true
        return cropVC
    }

    func updateUIViewController(_ uiViewController: TOCropViewController, context: Context) {}

    class Coordinator: NSObject, TOCropViewControllerDelegate {
        let parent: CropView
        init(_ parent: CropView) { self.parent = parent }

        func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
            parent.onCropped(image)
            parent.presentationMode.wrappedValue.dismiss()
        }

        func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
