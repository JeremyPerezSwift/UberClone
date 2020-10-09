//
//  LocationInputActivationView.swift
//  UberClone
//
//  Created by Jérémy Perez on 08/10/2020.
//

import UIKit

protocol LocationInputActivationViewDelegate: AnyObject {
    func presentLocationInputView()
}

class LocationInputActivationView: UIView {
    
    // MARK: Properties
    
    var delegate: LocationInputActivationViewDelegate?
    
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Where to ?"
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .darkGray
        return label
    }()
    
    // MARK: - Lifrecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addShadow()
        
        addSubview(indicatorView)
        indicatorView.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 16)
        indicatorView.setDimensions(width: 6, height: 6)
        
        addSubview(titleLabel)
        titleLabel.centerY(inView: self, leftAnchor: indicatorView.rightAnchor, paddingLeft: 20)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleShowLocationInputView))
        addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Selectors
    
    @objc func handleShowLocationInputView() {
        delegate?.presentLocationInputView()
    }
    
}
