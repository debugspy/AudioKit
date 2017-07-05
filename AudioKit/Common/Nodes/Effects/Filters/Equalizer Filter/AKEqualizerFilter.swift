//
//  AKEqualizerFilter.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2017 Aurelius Prochazka. All rights reserved.
//

/// A 2nd order tunable equalization filter that provides a peak/notch filter
/// for building parametric/graphic equalizers. With gain above 1, there will be
/// a peak at the center frequency with a width dependent on bandwidth. If gain
/// is less than 1, a notch is formed around the center frequency.
///
open class AKEqualizerFilter: AKNode, AKToggleable, AKComponent {
    public typealias AKAudioUnitType = AKEqualizerFilterAudioUnit
    /// Four letter unique description of the node
    public static let ComponentDescription = AudioComponentDescription(effect: "eqfl")

    // MARK: - Properties

    private var internalAU: AKAudioUnitType?
    private var token: AUParameterObserverToken?

    fileprivate var centerFrequencyParameter: AUParameter?
    fileprivate var bandwidthParameter: AUParameter?
    fileprivate var gainParameter: AUParameter?

    /// Ramp Time represents the speed at which parameters are allowed to change
    open dynamic var rampTime: Double = AKSettings.rampTime {
        willSet {
            internalAU?.rampTime = newValue
        }
    }

    /// Center frequency. (in Hertz)
    open dynamic var centerFrequency: Double = 1_000.0 {
        willSet {
            if centerFrequency != newValue {
                if internalAU?.isSetUp() ?? false {
                    if let existingToken = token {
                        centerFrequencyParameter?.setValue(Float(newValue), originator: existingToken)
                    }
                } else {
                    internalAU?.centerFrequency = Float(newValue)
                }
            }
        }
    }
    /// The peak/notch bandwidth in Hertz
    open dynamic var bandwidth: Double = 100.0 {
        willSet {
            if bandwidth != newValue {
                if internalAU?.isSetUp() ?? false {
                    if let existingToken = token {
                        bandwidthParameter?.setValue(Float(newValue), originator: existingToken)
                    }
                } else {
                    internalAU?.bandwidth = Float(newValue)
                }
            }
        }
    }
    /// The peak/notch gain
    open dynamic var gain: Double = 10.0 {
        willSet {
            if gain != newValue {
                if internalAU?.isSetUp() ?? false {
                    if let existingToken = token {
                        gainParameter?.setValue(Float(newValue), originator: existingToken)
                    }
                } else {
                    internalAU?.gain = Float(newValue)
                }
            }
        }
    }

    /// Tells whether the node is processing (ie. started, playing, or active)
    open dynamic var isStarted: Bool {
        return internalAU?.isPlaying() ?? false
    }

    // MARK: - Initialization

    /// Initialize this filter node
    ///
    /// - Parameters:
    ///   - input: Input node to process
    ///   - centerFrequency: Center frequency in Hertz
    ///   - bandwidth: The peak/notch bandwidth in Hertz
    ///   - gain: The peak/notch gain
    ///
    public init(
        _ input: AKNode?,
        centerFrequency: Double = 1_000.0,
        bandwidth: Double = 100.0,
        gain: Double = 10.0) {

        self.centerFrequency = centerFrequency
        self.bandwidth = bandwidth
        self.gain = gain

        _Self.register()

        super.init()
        AVAudioUnit._instantiate(with: _Self.ComponentDescription) { [weak self] avAudioUnit in

            self?.avAudioNode = avAudioUnit
            self?.internalAU = avAudioUnit.auAudioUnit as? AKAudioUnitType

            input?.addConnectionPoint(self!)
        }

        guard let tree = internalAU?.parameterTree else {
            return
        }

        centerFrequencyParameter = tree["centerFrequency"]
        bandwidthParameter = tree["bandwidth"]
        gainParameter = tree["gain"]

        token = tree.token (byAddingParameterObserver: { [weak self] address, value in

            DispatchQueue.main.async {
                if address == self?.centerFrequencyParameter?.address {
                    self?.centerFrequency = Double(value)
                } else if address == self?.bandwidthParameter?.address {
                    self?.bandwidth = Double(value)
                } else if address == self?.gainParameter?.address {
                    self?.gain = Double(value)
                }
            }
        })

        internalAU?.centerFrequency = Float(centerFrequency)
        internalAU?.bandwidth = Float(bandwidth)
        internalAU?.gain = Float(gain)
    }

    // MARK: - Control

    /// Function to start, play, or activate the node, all do the same thing
    open func start() {
        internalAU?.start()
    }

    /// Function to stop or bypass the node, both are equivalent
    open func stop() {
        internalAU?.stop()
    }
}
